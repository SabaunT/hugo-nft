//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./HugoNFTMetadataManager.sol";

/** TODO
0. TESTS
1. update traits info/
2. "info" contracts with fns used by HugoNFT users
3. error model
4. questions:
- check for duplicate traits (?)
- script update (?)
- events needed (?)
- pub function "isSeedUsed" - is version of seed considered?
5. uri for traits
6. abi encode to simplify hashing seed
7. move Hugo info fn to HugoNFTWithInfo, which will be the most derived
*/

contract HugoNFT is HugoNFTMetadataManager, ERC721Enumerable {
    event Mint(address indexed to, uint256 indexed tokenId, string name);
    event ChangeName(uint256 indexed tokenId, string name);
    event ChangeDescription(uint256 indexed tokenId, string description);

    constructor(
        string memory baseTokenURI,
        uint256 attributesAmount,
        string memory script
    )
        ERC721("Hugo", "HUGO")
    {
        require(bytes(baseTokenURI).length > 0, "HugoNFT::empty new URI string provided");
        require(attributesAmount > 0, "HugoNFT::attributes amount is 0");
        require(bytes(script).length > 0,"HugoNFT::empty nft generation script provided");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _baseTokenURI = baseTokenURI;
        _attributesAmount = attributesAmount;
        nftGenerationScripts.push(Script(script, true));

        isPaused = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256[] calldata seed,
        string calldata name,
        string calldata description
    )
        external
        whenIsNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(
            _getGeneratedHugoAmount() < generatedHugoCap,
            "HugoNFT::supply cap was reached"
        );
        require(_isValidSeed(seed), "HugoNFT::seed is invalid");
        // not to call twice
        bytes32 seedHash = _getSeedHash(seed);
        require(_isNewSeed(seedHash), "HugoNFT::seed is used");
        require(
            bytes(name).length > 0 && bytes(name).length <= 75,
            "HugoNFT::invalid NFT name length"
        );
        require(
            bytes(description).length > 0 && bytes(description).length <= 300,
            "HugoNFT::invalid NFT description length"
        );

        uint256 newTokenId = _getNewIdForGeneratedHugo();
        super._safeMint(to, newTokenId);

        _generatedNFTs[newTokenId] = GeneratedNFT(newTokenId, seed, name, description);
        _isUsedSeed[seedHash] = true;

        emit Mint(to, newTokenId, name);
    }

    function mintExclusive(
        address to,
        string calldata name,
        string calldata description
    )
        external
        whenIsNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(
            bytes(name).length > 0 && bytes(name).length <= 75,
            "HugoNFT::invalid NFT name length"
        );
        require(
            bytes(description).length > 0 && bytes(description).length <= 300,
            "HugoNFT::invalid NFT description length"
        );

        uint256 newTokenId = _getNewIdForExclusiveHugo();
        super._safeMint(to, newTokenId);
        _exclusiveNFTsAmount += 1;

        _exclusiveNFTs[newTokenId] = ExclusiveNFT(newTokenId, name, description);

        emit Mint(to, newTokenId, name);
    }

    function changeNFTName(uint256 tokenId, string calldata name) external {
        require(
            ownerOf(tokenId) == _msgSender(),
            "HugoNFT::token id isn't owned by msg sender"
        );
        require(
            bytes(name).length > 0 && bytes(name).length <= 75,
            "HugoNFT::invalid NFT name length"
        );

        if (_isIdOfGeneratedNFT(tokenId)) {
            _generatedNFTs[tokenId].name = name;
        } else {
            _exclusiveNFTs[tokenId].name = name;
        }

        emit ChangeName(tokenId, name);
    }

    function changeNFTDescription(uint256 tokenId, string calldata description) external {
        require(
            ownerOf(tokenId) == _msgSender(),
            "HugoNFT::token id isn't owned by msg sender"
        );
        require(
            bytes(description).length > 0 && bytes(description).length <= 300,
            "HugoNFT::invalid NFT description length"
        );

        if (_isIdOfGeneratedNFT(tokenId)) {
            _generatedNFTs[tokenId].description = description;
        } else {
            _exclusiveNFTs[tokenId].description = description;
        }

        emit ChangeDescription(tokenId, description);
    }

    /// ----------------------------- Info functions ----------------------------- \\\
    function amountOfAttributes() external view returns (uint256) {
        return _attributesAmount;
    }

    // todo get valid/invalid?
    function getLastAttributesCIDs() external view returns (string[] memory) {
        string[] memory retCIDs = new string[](_attributesAmount);
        for (uint256 i = 0; i < _attributesAmount; i++) {
            AttributeIpfsCID[] storage aCIDs = _attributeCIDs[i];
            if (aCIDs.length > 0) {
                AttributeIpfsCID storage lastCID = aCIDs[aCIDs.length - 1];
                retCIDs[i] = lastCID.cid;
            } else {
                retCIDs[i] = "";
            }
        }
        return retCIDs;
    }

    function getCIDsOfAttribute(uint256 attributeId)
        external
        view
        returns (AttributeIpfsCID[] memory)
    {
        return _attributeCIDs[attributeId];
    }

    function getTraitsOfAttribute(uint256 attributeId)
        external
        view
        returns (Trait[] memory)
    {
        return _traitsOfAttribute[attributeId];
    }

    /**
     * @dev Gets tokens owned by the `account`.
     *
     * *Warning*. Never call on-chain. Call only using web3 "call" method!
     */
    function tokenIdsOfOwner(address account)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenAmount = balanceOf(account);
        if (tokenAmount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory output = new uint256[](tokenAmount);
            for (uint256 index = 0; index < tokenAmount; index++) {
                output[index] = tokenOfOwnerByIndex(account, index);
            }
            return output;
        }
    }

    // todo check seed is correct by checking whether first 5 of them are non zero
    function isUsedSeed(uint256[] calldata seed) public view returns (bool) {
        return _isUsedSeed[_getSeedHash(seed)];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// -------------------- Private functions for core logic -------------------- \\\

    // Checks seed length, validity of trait ids and whether it was used
    function _isValidSeed(uint256[] calldata seed) private view returns (bool) {
        if (seed.length != _attributesAmount) return false;
        return _areValidTraitIds(seed);
    }

    // Seed length isn't checked, because was done previously in {HugoNFT-_isValidSeed}
    function _areValidTraitIds(uint256[] calldata seed) private view returns (bool) {
        for (uint256 i = 0; i < seed.length; i++ ) {
            // That's one of reasons why traits are added sequentially.
            // If IDs weren't provided sequentially, the only check we could do is
            // by accessing a trait in some mapping, that stores info whether the trait
            // with the provided id is present or not.
            uint256 numOfTraits = _traitsOfAttribute[i].length;
            // trait ids start from 1 and are defined
            // in a sequential order in contract state.
            if (seed[i] > numOfTraits || seed[i] == 0) return false;
        }
        return true;
    }

    // Just for convenience and readability
    function _isNewSeed(bytes32 seed) private view returns (bool) {
        return !_isUsedSeed[seed];
    }

    // Ids are from 0 to 9999. All in all, 10'000 generated hugo NFTs.
    // A check whether an NFT could be minted with a valid id is done
    // in the {HugoNFT-mint}.
    function _getNewIdForGeneratedHugo() private view returns (uint256) {
        return _getGeneratedHugoAmount();
    }

    function _getGeneratedHugoAmount() private view returns (uint256) {
        return totalSupply() - _exclusiveNFTsAmount;
    }

    // Ids are from 10'000 and etc.
    function _getNewIdForExclusiveHugo() private view returns (uint256) {
        return generatedHugoCap + _exclusiveNFTsAmount;
    }

    // Seed length isn't checked, because was done previously in {HugoNFT-_isValidSeed}
    function _getSeedHash(uint256[] calldata seed) private pure returns (bytes32) {
        bytes memory seedBytes = _traitIdToBytes(seed[0]);
        for (uint256 i = 1; i < seed.length; i++) {
            uint256 traitId = seed[i];
            seedBytes = bytes.concat(seedBytes, bytes32(traitId));
        }
        return keccak256(seedBytes);
    }

    // todo move to utils
    function _traitIdToBytes(uint256 traitId) private pure returns (bytes memory) {
        bytes32 traitIdBytes32 = bytes32(traitId);
        bytes memory traitIdBytes = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            traitIdBytes[i] = traitIdBytes32[i];
        }
        return traitIdBytes;
    }

    function _isIdOfGeneratedNFT(uint256 tokenId) private pure returns (bool) {
        return tokenId < generatedHugoCap;
    }
}

//contract HugoNFT is ERC721Enumerable {
//
//    /**
//     * Constants defining attributes ids in {HugoNFT-_traitsOfAttribute} mapping
//     */
//    uint256 constant public HEAD_ID = 0;
//    uint256 constant public GLASSES_ID = 1;
//    uint256 constant public BODY_ID = 2;
//    uint256 constant public SHIRT_ID = 3;
//    uint256 constant public SCARF_ID = 4;
//
//    // access by admin only
//    function setTokenURI(string calldata newURI) external {
//        // check for regex?
//        require(bytes(newURI).length > 0, "HugoNFT::empty new URI string provided");
//        require(
//            keccak256(abi.encodePacked(newURI)) != keccak256(abi.encodePacked(_baseTokenURI)),
//            "HugoNFT::can't set same token URI"
//        );
//
//        _baseTokenURI = newURI;
//    }
//}

//    function getTokenInfo(uint256 tokenId)
//        external
//        view
//        returns (
//            string memory name,
//            string memory description,
//            uint256[] memory seed
//        )
//    {
//        name = getTokenName(tokenId);
//        description = getTokenDescription(tokenId);
//        seed = getTokenSeed(tokenId);
//    }
//
//    function getTraitsOfAttribute(uint256 attributeId)
//        external
//        view
//        returns(Trait[] memory)
//    {
//        require(attributeId < _attributesAmount, "HugoNFT::invalid attribute id");
//        return _traitsOfAttribute[attributeId];
//    }

//    function getTokenSeed(uint256 id) public view returns(uint256[] memory) {
//        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
//        return _tokenSeed[id];
//    }
//
//    function getTokenName(uint256 id) public view returns(string memory) {
//        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
//        return _tokenName[id];
//    }
//
//    function getTokenDescription(uint256 id) public view returns(string memory) {
//        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
//        return _tokenDescription[id];
//    }
//    }