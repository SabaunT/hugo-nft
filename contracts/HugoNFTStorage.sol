//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./HugoNFTTypes.sol";

/**
 * 1. Storage for attributes (struct) and for getting ids of attributes
 * 2. Getting name, description (and info) from storage
 * 3. Script should be changed in attribute manager
 */
contract HugoNFTStorage is HugoNFTTypes {
    // The flag that indicates whether main contract procedures (minting) can work.
    // It is set to false in several situations:
    // 1. One of attributes has no traits
    // 2. IPFS hash of attribute isn't set or is invalid due to adding new trait
    bool public isPaused;

    // Amount of exclusive NFTs
    uint256 public exclusiveNFTsAmount;

    // amount of attributes used to generate NFT
    uint256 public attributesAmount;

    // Available to mint amount of auto-generated NFTs.
    uint256 public constant generatedHugoCap = 10000;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant NFT_ADMIN_ROLE = keccak256("NFT_ADMIN_ROLE");

    // Length of the CID in base58 representation
    uint256 internal constant IPFS_CID_BYTES_LENGTH = 46;
    uint256 internal constant MAX_ADDING_TRAITS = 25;

    string internal _baseTokenURI;

    // todo if we decide to allow minting with any valid attributes amount
    // Min amount of attributes that an NFT should have.
    // Defined by initial value of attributesAmount
//    uint256 internal minAttributesAmount;

    // Script that is used to generate NFTs from traits
    Script[] internal nftGenerationScripts;

    // token id => generated hugo.
    mapping(uint256 => GeneratedNFT) internal _generatedNFTs;

    // token id => exclusive hugo.
    mapping(uint256 => ExclusiveNFT) internal _exclusiveNFTs;

    // keccak256 of seed => boolean. Shows whether seed was used or not.
    mapping(bytes32 => bool) internal _isUsedSeed;

    // attribute id => traits of the attribute
    mapping(uint256 => Trait[]) internal _traitsOfAttribute;

    // rarity level => traits of the level
    mapping(Rarity => Trait[]) internal _traitsOfRarity;

    // attribute id => ipfs cid of the folder, where traits are stored
    mapping(uint256 => AttributeIpfsCID[]) internal _CIDsOfAttribute;
}

// There is a contract in order of values in seeds, cids, and such - the layout is
// in accordance to the following order of attributes [HEAD_ID, GLASSES_ID, BODY_ID, SHIRT_ID, SCARF_ID]
