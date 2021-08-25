//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/** TODO
1. Roles
2. events
3. changeable names and descriptions for NFTs
5. update traits info
6. loop boundaries
7. duplicate traits
*/

/**
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
}

/**
 * 1. Storage for attributes (struct) and for getting ids of attributes
 * 2. Getting name, description (and info) from storage
 * 3. Script should be changed in attribute manager
 */
// There is a contract in order of values in seeds, cids, and such - the layout is
// in accordance to the following order of attributes [HEAD_ID, GLASSES_ID, BODY_ID, SHIRT_ID, SCARF_ID]
contract HugoNFTStorage is HugoNFTTypes {
    string internal constant EMPTY_IPFS_CID_STRING = "";
    // Length of the CID in base58 representation
    uint256 internal constant IPFS_CID_BYTES_LENGTH = 46;

    // Script that is used to generate NFTs from traits
    Script[] nftGenerationScripts;

    // amount of attributes used to generate NFT
    uint256 internal _attributesAmount;

    // token id => seed. Seed is an array of trait ids.
    // A 0 value of token id is reserved for "no attribute" in the seed array
    mapping(uint256 => uint256[]) internal _tokenSeed;

    // attribute id => traits of the attribute
    mapping(uint256 => Trait[]) internal _traitsOfAttribute;

    // attribute id => ipfs cid of the folder, where traits are stored
    mapping(uint256 => AttributeIpfsCID[]) internal _attributeCIDs;
}

contract HugoNFTMetadataManager is HugoNFTStorage {

    // The flag that indicates whether main contract procedures (minting) can work.
    // It is set to false in several situations:
    // 1. One of attributes has no traits
    // 2. IPFS hash of attribute isn't set or is invalid due to adding new trait
    bool isPaused;

    modifier whenIsNotPaused() {
        require(!isPaused, "HugoNFT::calling action in a paused state");
        _;
    }

    // todo access by admin only
    function addNewAttributeAndTraits(
        uint256[] memory traitIds,
        string[] memory names,
        Rarity[] memory rarities
    )
        external
    {
        uint256 newAttributeId = _attributesAmount;
        _attributesAmount += 1;
        addTraits(newAttributeId, traitIds, names, rarities);
    }

    // todo access by admin only
    // If for some attribute it wasn't intended to update the hash, then
    // an empty string should be sent as an array member.
    function updateMultipleAttributesHashes(string[] memory CIDs) external {
        require(
            CIDs.length == _attributesAmount,
            "HugoNFT::invalid cids array length"
        );
        for (uint256 i = 0; i < CIDs.length; i++) {
            if (CIDs[i] == EMPTY_IPFS_CID_STRING) continue;
            updateAttributeHash(i, CIDs[i]);
        }
    }

    // todo access by admin only
    // todo Reverts if one of valid attributes is empty: just for safety not to call the function many times setting the same hash
    function updateAttributeHash(uint256 attributeId, string memory ipfsCID) public {
        require(attributeId < _attributesAmount, "HugoNFT::invalid attribute id");
        require(
            bytes(ipfsCID).length == IPFS_CID_BYTES_LENGTH,
            "HugoNFT::invalid ipfs CID length"
        );

        AttributeIpfsCID[] storage CIDs = _attributeCIDs[attributeId];
        if (CIDs.length > 0) {
            AttributeIpfsCID storage lastCID = CIDs[CIDs.length - 1];
            if (lastCID.isValid) lastCID.isValid = false;
        }
        CIDs.push(AttributeIpfsHash(ipfsCID, true));

        if (isPaused && checkAllCIDsAreValid()) {
            isPaused = false;
        }
    }

    // todo access
    function addTraits(
        uint256 attributeId,
        uint256[] memory traitIds,
        string[] memory names,
        Rarity[] memory rarities
    )
        external
    {
        require(
            traitIds.length == names.length && names.length == rarities.length,
            "HugoNFT::unequal lengths of trait inner data arrays"
        );
        for (uint256 i = 0; i < traitIds.length; i++) {
            addTrait(attributeId, traitIds[i], names[i], rarities[i]);
        }
    }

    // todo access
    function addTrait(
        uint256 attributeId,
        uint256 traitId,
        string calldata name,
        Rarity rarity
    )
        public
    {
        require(attributeId < _attributesAmount, "HugoNFT::invalid attribute id");
        require(
            traitId != 0,
            "HugoNFT::0 trait id is reserved for 'no attribute' in seed"
        );
        // This kind of check has 2 pros:
        // 1. could check whether the id is valid by comparing it with array length
        // 2. trait id also tells about its position in Traits[]
        // But there is a con: we should add traits sequentially
        Trait[] storage tA = _traitsOfAttribute[attributeId];
        require(
            tA.length == newTraitId,
            "HugoNFT::traits should be added sequentially"
        );
        require(bytes(name).length > 0, "HugoNFT::empty trait name");

        tA.push(Trait(traitId, name, rarity));

        if (!isPaused) isPaused = true;
    }

    function checkAllCIDsAreValid() private view returns (bool) {
        for (uint256 i = 0; i < _attributesAmount; i++) {
            AttributeIpfsCID[] storage CIDs = _attributeCIDs[i];
            if (CIDs.length == 0) return false;
            AttributeIpfsCID storage lastCID = CIDs[CIDs.length - 1];
            if (!lastCID.isValid) return false;
        }
        return true;
    }
}

//contract HugoNFT is ERC721Enumerable {
//
//    bool isPaused;
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
//    // Available to mint amount of NFTs.
//    uint256 constant public supplyCap = 10000;
//
//    string private _baseTokenURI;
//
//    constructor(
//        string memory baseTokenURI,
//        uint256 attributesAmount,
//        string memory script
//    )
//    ERC721("Hugo", "HUGO")
//    {
//        require(bytes(baseTokenURI).length > 0, "HugoNFT::empty new URI string provided");
//        require(bytes(script).length > 0,"HugoNFT::empty nft generation script provided");
//        require(attributesAmount > 0, "HugoNFT::attributes amount is 0");
//
//        _baseTokenURI = baseTokenURI;
//        _attributesAmount = attributesAmount;
//        nftGenerationScript = script;
//
//        isPaused = true;
//    }
//
//    // access by admin and shop
//    // check whose beforeTransfer is called
//    function mint(
//        address to,
//        uint256[] calldata seed,
//        string memory name,
//        string memory description
//    )
//    external
//    whenCanMint
//    {
//        require(_isValidSeed(seed), "HugoNFT::seed is invalid");
//        require(bytes(name).length <= 60, "HugoNFT::too long NFT name");
//        require(bytes(description) <= 250, "HugoNFT::too long NFT description");
//        require(totalSupply() < supplyCap, "HugoNFT::supply cap was reached");
//
//        uint256 newTokenId = totalSupply();
//        super._safeMint(to, newTokenId);
//
//        _tokenSeed[newTokenId] = seed;
//        _tokenName[newTokenId] = name;
//        _tokenDescription[newTokenId] = description;
//    }
//
//    // access by admin only
//    // check whose beforeTransfer is called
//    // supplyCap a restriction here as well?
//    function mintExclusive(
//        address to,
//        string memory name,
//        string memory description
//    )
//    external
//    whenCanMint
//    {
//        require(bytes(name).length <= 60, "HugoNFT::too long NFT name");
//        require(bytes(description) <= 250, "HugoNFT::too long NFT description");
//        // todo - nope, they have another approach in Ids
//        uint256 newTokenId = totalSupply();
//        super._safeMint(to, newTokenId);
//    }
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
//
//
//    function _baseURI() internal view override returns (string memory) {
//        return _baseTokenURI;
//    }
//
//    // return error
//    // ids in seed should follow the "contract" of attributes layout [HEAD_ID, GLASSES_ID, BODY_ID, SHIRT_ID, SCARF_ID]
//    function _isValidSeed(uint256[] calldata seed) private view returns (bool) {
//        if (seed.length != _attributesAmount) return false;
//
//        for (uint256 i = 0; i < _attributesAmount; i++ ) {
//            // if IDs weren't provided sequentially, the only check we could do is
//            // by accessing a trait in some mapping, that stores info whether they are
//            // present or not.
//            uint256 numOfTraits = _traitsOfAttribute[i].length;
//            if (seed[i] >= numOfTraits) return false;
//        }
//        return true;
//    }
//
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

//    /**
//     * @dev Gets tokens owned by the `account`.
//     *
//     * *Warning*. Never call on-chain. Call only using web3 "call" method!
//     */
//    function tokensOfOwner(address account)
//        external
//        view
//        returns (uint256[] memory ownerTokens)
//    {
//        uint256 tokenAmount = balanceOf(account);
//        if (tokenAmount == 0) {
//            return new uint256[](0);
//        } else {
//            uint256[] memory output = new uint256[](tokenAmount);
//            for (uint256 index = 0; index < tokenAmount; index++) {
//                output[index] = tokenOfOwnerByIndex(account, index);
//            }
//            return output;
//        }
//    }