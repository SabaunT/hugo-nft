//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./HugoNFTMetadataManager.sol";

abstract contract HugoNFTMinter is HugoNFTMetadataManager, ERC721 {
    event Mint(address indexed to, uint256 indexed tokenId, string name);
    event ChangeName(uint256 indexed tokenId, string name);
    event ChangeDescription(uint256 indexed tokenId, string description);

    function mint(
        address to,
        uint256[] calldata seed,
        string calldata name,
        string calldata description
    )
        external
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

        totalSupply += 1;

        uint256[] storage tIdsOfA = _tokenIdsOfAddress[to];
        uint256 idInArrayOfIds = tIdsOfA.length;

        tIdsOfA.push(newTokenId);
        _NFTs[newTokenId] = NFT(newTokenId, name, description, seed, "", idInArrayOfIds);
        _isUsedSeed[seedHash] = true;

        emit Mint(to, newTokenId, name);
    }

    function mintExclusive(
        address to,
        string calldata name,
        string calldata description,
        string calldata cid
    )
        external
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
        require(
            bytes(cid).length == IPFS_CID_BYTES_LENGTH,
            "HugoNFT::invalid ipfs CID length"
        );

        uint256 newTokenId = _getNewIdForExclusiveHugo();
        super._safeMint(to, newTokenId);

        totalSupply += 1;
        exclusiveNFTsAmount += 1;

        uint256[] storage tIdsOfA = _tokenIdsOfAddress[to];
        uint256 idInArrayOfIds = tIdsOfA.length;

        tIdsOfA.push(newTokenId);
        _NFTs[newTokenId] = NFT(newTokenId, name, description, new uint256[](0), cid, idInArrayOfIds);

        emit Mint(to, newTokenId, name);
    }

    function changeNFTName(uint256 tokenId, string calldata name)
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(_tokenExists(tokenId), "HugoNFT::nft with such id doesn't exist");
        require(
            bytes(name).length > 0 && bytes(name).length <= 75,
            "HugoNFT::invalid NFT name length"
        );
        _NFTs[tokenId].name = name;

        emit ChangeName(tokenId, name);
    }

    function changeNFTDescription(uint256 tokenId, string calldata description)
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(_tokenExists(tokenId), "HugoNFT::nft with such id doesn't exist");
        require(
            bytes(description).length > 0 && bytes(description).length <= 300,
            "HugoNFT::invalid NFT description length"
        );

        _NFTs[tokenId].description = description;

        emit ChangeDescription(tokenId, description);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // Does nothing as ERC721._beforeTokenTransfer has no logic
        super._beforeTokenTransfer(from, to, tokenId);

        // transferFrom was called
        if (from != address(0)) {
            uint256[] storage tokenIdsFrom = _tokenIdsOfAddress[from];
            uint256[] storage tokenIdsTo = _tokenIdsOfAddress[to];
            NFT storage transferringNFT = _NFTs[tokenId];

            uint256 lastIndexInIdsFrom = tokenIdsFrom.length - 1;
            uint256 transferringTokenIndex = transferringNFT.index;

            if (transferringTokenIndex != lastIndexInIdsFrom) {
                uint256 lastIdFrom = tokenIdsFrom[lastIndexInIdsFrom];
                NFT storage lastNFTFrom = _NFTs[lastIdFrom];

                tokenIdsFrom[transferringTokenIndex] = lastNFTFrom.tokenId;
                lastNFTFrom.index = transferringTokenIndex;
            }

            uint256 transferringTokenNewIndex = tokenIdsTo.length;
            tokenIdsTo.push(tokenId);
            transferringNFT.index = transferringTokenNewIndex;

            tokenIdsFrom.pop();
        }
    }

    // Seed length isn't checked, because was done previously in {HugoNFT-_isValidSeed}
    // Should be called only after seed was validated!
    // Returns the hash of the the same input seed, but with one modification:
    // it has right trailing zeroes in it truncated.
    // For example:
    // 1. _getSeedHash([1,2,3,0,0]) -> hash([1,2,3])
    // 2. _getSeedHash([1,2,3,0,1]) -> hash([1,2,3,0,1])
    function _getSeedHash(uint256[] calldata validSeed) internal view returns (bytes32) {
        uint256[] memory validSeedNoTrailingZeroes = _getWithoutTrailingZeroes(validSeed);
        bytes memory seedBytes = new bytes(32 * validSeedNoTrailingZeroes.length);
        for (uint256 i = 0; i < validSeedNoTrailingZeroes.length; i++) {
            uint256 traitId = validSeedNoTrailingZeroes[i];
            // If seed wasn't valid, then this check could cause problems
            // like skipping an attribute of first `minAttributesAmount` core ones.
            seedBytes = bytes.concat(seedBytes, bytes32(traitId));
        }
        return keccak256(seedBytes);
    }

    // Checks seed length, validity of trait ids and whether it was used
    function _isValidSeed(uint256[] calldata seed) internal view returns (bool) {
        if (seed.length > attributesAmount || seed.length < minAttributesAmount) {
            return false;
        }
        return _areValidTraitIds(seed);
    }

    function _isIdOfGeneratedNFT(uint256 tokenId) internal pure returns (bool) {
        return tokenId < generatedHugoCap;
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        NFT storage nft = _NFTs[tokenId];
        return nft.tokenId == tokenId;
    }

    function _getGeneratedHugoAmount() internal view returns (uint256) {
        return totalSupply - exclusiveNFTsAmount;
    }

    // Seed length isn't checked, because was done previously in {HugoNFT-_isValidSeed}
    function _areValidTraitIds(uint256[] calldata seed) private view returns (bool) {
        for (uint256 i = 0; i < seed.length; i++ ) {
            // That's one of reasons why traits are added sequentially.
            // If IDs weren't provided sequentially, the only check we could do is
            // by accessing a trait in some mapping, that stores info whether the trait
            // with the provided id is present or not.
            uint256 numOfTraits = _traitsOfAttribute[i].length;
            // Trait ids start from 1 and are defined in a sequential order.
            // Zero trait id is possible - it means that generating NFT won't have
            // such attribute. It's possible only for those attributes, which were
            // added after deployment.
            if ((i < minAttributesAmount && seed[i] == 0) || seed[i] > numOfTraits) {
                return false;
            }
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

    // Ids are from 10'000 and etc.
    function _getNewIdForExclusiveHugo() private view returns (uint256) {
        return generatedHugoCap + exclusiveNFTsAmount;
    }

    function _getWithoutTrailingZeroes(uint256[] calldata validSeed)
        private
        view
        returns
        (uint256[] memory)
    {
        uint256 end = validSeed.length;
        for (uint256 i = validSeed.length - 1; i >= minAttributesAmount; i--) {
            if (validSeed[i] != 0) { break ;}
            end = i;
        }
        return validSeed[:end];
    }
}