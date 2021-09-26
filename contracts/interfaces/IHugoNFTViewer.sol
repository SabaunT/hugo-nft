//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../HugoNFTTypes.sol";

// @dev Main purpose is to provide an interface for front-end dev.
interface IHugoNFTViewer {
    //// ----------------------------------------------- \\\\
    //// ---------------- View functions --------------- \\\\
    //// ----------------------------------------------- \\\\

    /**
     * @dev Gets script actual for `attributesNum` number of attributes
     *
     * Returns a utf-8 string of the script
     */
    function getGenerationScriptForAttributesNum(uint256 attributesNum)
        external
        view
        returns (string memory);

    // @dev Returns an amount of auto-generated NFTs already minted.
    function generatedNFTsAmount() external view returns (uint256);

    /**
     * @dev Gets CIDs array for an `attributeId`
     *
     * Returns an array of utf-8 IPFS CID strings
     */
    function getCIDsOfAttribute(uint256 attributeId)
        external
        view
        returns (string[] memory);

    /**
     * @dev Gets traits array for an `attributeId`
     *
     * Returns an array of {HugoNFTType-Trait}s
     */
    function getTraitsOfAttribute(uint256 attributeId)
        external
        view
        returns (HugoNFTTypes.Trait[] memory);

    // @dev Returns an array of token ids owned by `account`.
    function tokenIdsOfOwner(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Checks whether the provided `seed` is used.
     *
     * Returns true if `seed` is used, otherwise - false.
     */
    function isUsedSeed(uint256[] calldata seed) external view returns (bool);

    // @dev Returns array of {HugoNFTType-NFT} structs, which have requested token ids.
    function getNFTs(uint256[] calldata tokenIds)
        external
        view
        returns (HugoNFTTypes.NFT[] memory);

    function getNFT(uint256 tokenId)
        external
        view
        returns (HugoNFTTypes.NFT memory);

    /**
     * @dev Gets IPFS path to `traitId` of `attributeId`
     *
     * Returns a utf-8 string of IPFS path to the requested trait.
     */
    function traitIpfsPath(uint256 attributeId, uint256 traitId)
        external
        view
        returns (string memory);
}

