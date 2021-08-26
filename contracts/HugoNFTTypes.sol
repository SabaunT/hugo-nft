//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/** todo
 * 1. AttributeStruct
 */
contract HugoNFTTypes {
    enum Rarity{COMMON, UNCOMMON, RARE, LEGENDARY}

    struct Trait {
        uint256 traitId;
        string name;
        Rarity rarity;
        //todo attribute
    }

    struct AttributeIpfsCID {
        string cid;
        bool isValid;
    }

    struct Script {
        string script;
        bool isValid;
    }

    struct GeneratedNFT {
        uint256 tokenId;
        // Seed is an array of trait ids.
        // A 0 value of token id is reserved for "no attribute" in the seed array
        uint256[] seed;
        string name;
        string description;
    }

    struct ExclusiveNFT {
        uint256 tokenId;
        string name;
        string description;
    }
}