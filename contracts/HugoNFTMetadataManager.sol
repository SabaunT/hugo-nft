//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./HugoNFTStorage.sol";

// Management for attributes, traits and hashes - all are named as meta-data.
contract HugoNFTMetadataManager is HugoNFTStorage, AccessControl {
    event AddNewAttribute(uint256 indexed newAttributeId);
    event AddNewTrait(uint256 indexed attributeId, uint256 indexed traitId, string name);
    event UpdateAttributeCID(uint256 indexed attributeId, string ipfsCID);

    modifier whenIsNotPaused() {
        require(!isPaused, "HugoNFT::calling action in a paused state");
        _;
    }

    function addNewAttributeWithTraits(
        uint256[] calldata traitIds,
        string[] calldata names,
        Rarity[] calldata rarities
    )
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        uint256 newAttributeId = _attributesAmount;
        _attributesAmount += 1;

        addTraits(newAttributeId, traitIds, names, rarities);

        emit AddNewAttribute(newAttributeId);
    }

    // If for some attribute it wasn't intended to update the hash, then
    // an empty string should be sent as an array member.
    function updateMultipleAttributesCIDs(string[] calldata CIDs)
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(
            CIDs.length <= _attributesAmount,
            "HugoNFT::invalid cids array length"
        );
        for (uint256 i = 0; i < CIDs.length; i++) {
            if (bytes(CIDs[i]).length == 0) continue;
            updateAttributeCID(i, CIDs[i]);
        }
    }

    // todo Reverts if one of valid attributes is empty: just for safety not to call the function many times setting the same hash
    function updateAttributeCID(uint256 attributeId, string calldata ipfsCID)
        public
        onlyRole(NFT_ADMIN_ROLE)
    {
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
        CIDs.push(AttributeIpfsCID(ipfsCID, true));

        if (isPaused && checkAllCIDsAreValid()) {
            isPaused = false;
        }

        emit UpdateAttributeCID(attributeId, ipfsCID);
    }

    function addTraits(
        uint256 attributeId,
        uint256[] calldata traitIds,
        string[] calldata names,
        Rarity[] calldata rarities
    )
        public
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(
            traitIds.length <= MAX_ADDING_TRAITS,
            "HugoNFT::adding traits number exceeds prohibited amount"
        );
        require(
            traitIds.length == names.length && names.length == rarities.length,
            "HugoNFT::unequal lengths of trait inner data arrays"
        );

        for (uint256 i = 0; i < traitIds.length; i++) {
            addTrait(attributeId, traitIds[i], names[i], rarities[i]);
        }
    }

    function addTrait(
        uint256 attributeId,
        uint256 traitId,
        string calldata name,
        Rarity rarity
    )
        public
        onlyRole(NFT_ADMIN_ROLE)
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
            tA.length == traitId,
            "HugoNFT::traits should be added sequentially"
        );
        require(bytes(name).length > 0, "HugoNFT::empty trait name");

        tA.push(Trait(traitId, name, rarity));

        if (!isPaused) isPaused = true;

        emit AddNewTrait(attributeId, traitId, name);
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