pragma solidity 0.8.7;

import "./HugoNFTStorage.sol";

// Management for attributes, traits and hashes - all are named as meta-data.
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
    public
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