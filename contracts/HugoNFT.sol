//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./HugoNFTMinter.sol";

/** TODO
1. update traits info/
2. error model
3. questions:
- check for duplicate traits (?)
- script update (?)
- events needed (?)
- pub function "isSeedUsed" - is version of seed considered?
- abi encode to simplify hashing seed (?)
4. uri for traits
*/

contract HugoNFT is HugoNFTMinter {
    constructor(
        string memory baseTokenURI,
        uint256 attributesAmount,
        string memory script
    )
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
    function isUsedSeed(uint256[] calldata seed) external view returns (bool) {
        return _isUsedSeed[_getSeedHash(seed)];
    }

    function getGeneratedToken(uint256 tokenId)
        external
        view
        returns (GeneratedNFT memory)
    {
        require(
            _isIdOfGeneratedNFT(tokenId),
            "HugoNFT::provided id out of generated token ids range"
        );
        GeneratedNFT memory retNFT = _generatedNFTs[tokenId];
        retNFT.seed = _standardizeSeed(retNFT.seed);
        return retNFT;
    }

    function getExclusiveToken(uint256 tokenId)
        external
        view
        returns (ExclusiveNFT memory)
    {
        require(
            !_isIdOfGeneratedNFT(tokenId),
            "HugoNFT::provided id out of exclusive token ids range"
        );
        return _exclusiveNFTs[tokenId];
    }

    function getTraitsByRarity(Rarity rarity) external view returns (Trait[] memory) {
        return _traitsOfRarity[rarity];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _standardizeSeed(uint256[] memory seed)
        private
        view
        returns (uint256[] memory)
    {
        if (seed.length == _attributesAmount) return seed;
        uint256[] memory standardizedSeed = new uint256[](_attributesAmount);
        for (uint256 i = 0; i < _attributesAmount; i++) {
            standardizedSeed[i] = i > seed.length - 1 ? 0 : seed[i];
        }
        return standardizedSeed;
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