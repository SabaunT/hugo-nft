//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./HugoNFTStorage.sol";

// Management for attributes, traits and hashes - all are named as meta-data.
contract HugoNFTMetadataManager is HugoNFTStorage, AccessControl {
    event AddNewAttribute(uint256 indexed newAttributeId);
    event AddNewTrait(uint256 indexed attributeId, uint256 indexed traitId, string name);
    event UpdateAttributeCID(uint256 indexed attributeId, string ipfsCID);

    function addNewAttributeWithTraits(
        uint256 amountOfTraits,
        string[] calldata names,
        Rarity[] calldata rarities,
        string calldata cid,
        string calldata newGenerationScript
    )
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        uint256 newAttributeId = currentAttributesAmount;
        currentAttributesAmount += 1;

        addTraits(newAttributeId, amountOfTraits, names, rarities, cid);

        nftGenerationScripts.push(newGenerationScript);

        emit AddNewAttribute(newAttributeId);
    }

    // If for some attribute it wasn't intended to update the hash, then
    // an empty string should be sent as an array member.
    function updateMultipleAttributesCIDs(string[] calldata CIDs)
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(
            CIDs.length == currentAttributesAmount,
            "HugoNFT::invalid cids array length"
        );
        for (uint256 i = 0; i < CIDs.length; i++) {
            if (bytes(CIDs[i]).length == 0) continue;
            updateAttributeCID(i, CIDs[i]);
        }
    }

    function addTrait(
        uint256 attributeId,
        uint256 traitId,
        string calldata name,
        Rarity rarity,
        string calldata cid
    )
        external
        onlyRole(NFT_ADMIN_ROLE)
    {
        addTraitWithoutCID(attributeId, traitId, name, rarity);
        updateAttributeCID(attributeId, cid);
    }

    function addTraits(
        uint256 attributeId,
        uint256 amountOfTraits,
        string[] memory names,
        Rarity[] memory rarities,
        string memory cid
    )
        public
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(
            amountOfTraits <= MAX_ADDING_TRAITS,
            "HugoNFT::adding traits number exceeds prohibited amount"
        );
        require(
            amountOfTraits == names.length && names.length == rarities.length,
            "HugoNFT::unequal lengths of trait inner data arrays"
        );

        uint256 startFromId = _traitsOfAttribute[attributeId].length;
        for (uint256 i = 0; i < amountOfTraits; i++) {
            addTraitWithoutCID(attributeId, startFromId + i + 1, names[i], rarities[i]);
        }
        updateAttributeCID(attributeId, cid);
    }

    function updateAttributeCID(uint256 attributeId, string memory ipfsCID)
        public
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(attributeId < currentAttributesAmount, "HugoNFT::invalid attribute id");
        require(
            bytes(ipfsCID).length == IPFS_CID_BYTES_LENGTH,
            "HugoNFT::invalid ipfs CID length"
        );

        _CIDsOfAttribute[attributeId].push(ipfsCID);

        emit UpdateAttributeCID(attributeId, ipfsCID);
    }

    function addTraitWithoutCID(
        uint256 attributeId,
        uint256 traitId,
        string memory name,
        Rarity rarity
    )
        private
        onlyRole(NFT_ADMIN_ROLE)
    {
        require(attributeId < currentAttributesAmount, "HugoNFT::invalid attribute id");
        // This kind of check has 2 pros:
        // 1. could check whether the id is valid by comparing it with array length
        // 2. trait id also tells about its position in Traits[]
        // But there is a con: we should add traits sequentially
        Trait[] storage tA = _traitsOfAttribute[attributeId];
        require(
            tA.length + 1 == traitId,
            "HugoNFT::traits should be added sequentially by trait ids"
        );
        require(bytes(name).length > 0, "HugoNFT::empty trait name");

        Trait memory newTrait = Trait(attributeId, traitId, name, rarity);
        tA.push(newTrait);

        emit AddNewTrait(attributeId, traitId, name);
    }
}