//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./HugoNFTMetadataManager.sol";
import "./ERC721EnumarableAbstract.sol";

abstract contract HugoNFTMinter is HugoNFTMetadataManager, ERC721EnumerableAbstract {
    event Mint(address indexed to, uint256 indexed tokenId, string name);
    event ChangeName(uint256 indexed tokenId, string name);
    event ChangeDescription(uint256 indexed tokenId, string description);

    constructor() ERC721("HUGO", "HUGO") {}

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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableAbstract, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Seed length isn't checked, because was done previously in {HugoNFT-_isValidSeed}
    function _getSeedHash(uint256[] calldata seed) internal pure returns (bytes32) {
        bytes memory seedBytes = _traitIdToBytes(seed[0]);
        for (uint256 i = 1; i < seed.length; i++) {
            uint256 traitId = seed[i];
            seedBytes = bytes.concat(seedBytes, bytes32(traitId));
        }
        return keccak256(seedBytes);
    }

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