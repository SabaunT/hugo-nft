//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./HugoNFTTypes.sol";


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

interface IHugoNFTMetadataManager {
    //// ----------------------------------------------- \\\\
    //// ------------- Metadata management ------------- \\\\
    //// ----------------------------------------------- \\\\

    // @dev Adds a new attribute to NFT.
    function addNewAttributeWithTraits(
        string calldata attributeName,
        uint256 amountOfTraits,
        string[] calldata names,
        string calldata cid,
        string calldata newGenerationScript
    )
    external;

    // @dev Updates multiple attribute's CIDs.
    function updateMultipleAttributesCIDs(string[] calldata CIDs)
    external;

    // @dev Adds a trait and updates CID.
    function addTrait(
        uint256 attributeId,
        uint256 traitId,
        string calldata name,
        string calldata cid
    )
    external;

    // @dev Adds new traits to the attribute.
    function addTraits(
        uint256 attributeId,
        uint256 amountOfTraits,
        string[] memory names,
        string memory cid
    )
    external;

    // @dev Updates attribute's CID.
    function updateAttributeCID(uint256 attributeId, string memory ipfsCID)
    external;
}

interface IHugoNFTMinter {
    //// ----------------------------------------------- \\\\
    //// ---------------- Minting logic ---------------- \\\\
    //// ----------------------------------------------- \\\\

    // @dev Mints a new auto-generative NFT with a seed for a `to` address.
    function mint(
        address to,
        uint256[] calldata seed,
        string calldata name,
        string calldata description
    )
    external;

    // @dev Mints a new exclusive NFT for a `to` address.
    function mintExclusive(
        address to,
        string calldata name,
        string calldata description,
        string calldata cid
    )
    external;

    // @dev Changes name of the NFT with provided tokenId.
    function changeNFTName(uint256 tokenId, string calldata name)
    external;

    // @dev Changes description of the NFT with provided tokenId.
    function changeNFTDescription(uint256 tokenId, string calldata description)
    external;
}

// @dev Main purpose is to provide an interface for front-end dev.
interface IHugoNFT is IHugoNFTViewer, IHugoNFTMinter, IHugoNFTMetadataManager {}

