//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./HugoNFTStorage.sol";

contract HugoNFTInfo is HugoNFTStorage {
    function amountOfAttributes() external view returns (uint256) {
        return _attributesAmount;
    }

    // todo get valid/invalid?
    function getLastAttributesCIDs() external view returns (string[] memory) {
        string[] memory retCIDs = new string[](_attributesAmount);
        for (uint256 i = 0; i < _attributesAmount; i++) {
            AttributeIpfsCID[] storage aCIDs = _attributeCIDs[i];
            if (aCIDs.length > 0) {
                AttributeIpfsCID storage lastCID = aCIDs[aCIDs.length - 1];
                retCIDs[i] = lastCID.cid;
            } else {
                retCIDs[i] = "";
            }
        }
        return retCIDs;
    }

    function getCIDsOfAttribute(uint256 attributeId)
        external
        view
        returns (AttributeIpfsCID[] memory)
    {
        return _attributeCIDs[attributeId];
    }

    function getTraitsOfAttribute(uint256 attributeId)
        external
        view
        returns (Trait[] memory)
    {
      return _traitsOfAttribute[attributeId];
    }
}
