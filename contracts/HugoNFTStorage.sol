//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./HugoNFTTypes.sol";

/**
 * 1. Storage for attributes (struct) and for getting ids of attributes
 * 2. Getting name, description (and info) from storage
 * 3. Script should be changed in attribute manager
 */
contract HugoNFTStorage is HugoNFTTypes {
    uint256 public totalSupply;

    // Amount of exclusive NFTs
    uint256 public exclusiveNFTsAmount;

    // amount of attributes used to generate NFT
    uint256 public currentAttributesAmount;

    // Available to mint amount of auto-generated NFTs.
    uint256 public constant generatedHugoCap = 10000;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant NFT_ADMIN_ROLE = keccak256("NFT_ADMIN_ROLE");

    // Length of the CID in base58 representation
    uint256 internal constant IPFS_CID_BYTES_LENGTH = 46;
    uint256 internal constant MAX_ADDING_TRAITS = 25;

    string internal _baseTokenURI;

    // Min amount of attributes that an NFT should have.
    // Defined by initial value of attributesAmount
    // Set only once in constructor.
    uint256 internal minAttributesAmount;

    // Script that is used to generate NFTs from traits
    string[] internal nftGenerationScripts;

    // address => token ids of the address
    // there is no order guaranteed
    mapping(address => uint256[]) internal _tokenIdsOfAddress;

    // token id => generated hugo.
    mapping(uint256 => NFT) internal _NFTs;

    // keccak256 of seed => boolean. Shows whether seed was used or not.
    mapping(bytes32 => bool) internal _isUsedSeed;

    // attribute id => traits of the attribute
    mapping(uint256 => Trait[]) internal _traitsOfAttribute;

    // attribute id => ipfs cid of the folder, where traits are stored
    mapping(uint256 => string[]) internal _CIDsOfAttribute;
}

// There is a contract in order of values in seeds, cids, and such - the layout is
// in accordance to the following order of attributes [HEAD_ID, GLASSES_ID, BODY_ID, SHIRT_ID, SCARF_ID]
