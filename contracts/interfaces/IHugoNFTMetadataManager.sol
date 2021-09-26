//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @dev Main purpose is to provide an interface for front-end dev.
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
