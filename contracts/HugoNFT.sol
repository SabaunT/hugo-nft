//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./HugoNFTMinter.sol";

/** TODO
2. Getting NFTs of a user. 2.1) Mapping (address=>ids[]) <- Remember to change it when transfers happen
2.2) Function that accepts a bunch if seeds and returns NFTs (can be used to get NFTs of the user)
3. error model
4. questions:
- script update -> yes, when attribute added
- events needed - да и подробнее, чтобы можно было восстановить стейт
5. какие трэйты имеют такой rarity для данного атрибута
*/

// This contract mainly stores view functions
contract HugoNFT is HugoNFTMinter {
    using Strings for uint256;

    // @notice Deploying with 25 traits and 5 attributes requires gas usage of ~20000000
    constructor(
        string memory baseTokenURI,
        uint256 initialAmountOfAttributes,
        string memory script,
        // attributes and traits params
        uint256[] memory traitAmountForEachAttribute,
        string[][] memory traitNamesForEachAttribute,
        Rarity[][] memory raritiesForEachAttribute,
        string[] memory CIDsForEachAttribute
    )
    {
        require(bytes(baseTokenURI).length > 0, "HugoNFT::empty new URI string provided");
        require(initialAmountOfAttributes > 0, "HugoNFT::initial attributes amount is 0");
        require(bytes(script).length > 0,"HugoNFT::empty nft generation script provided");
        require(
            (initialAmountOfAttributes == traitAmountForEachAttribute.length) &&
            (initialAmountOfAttributes == traitNamesForEachAttribute.length) &&
            (initialAmountOfAttributes == raritiesForEachAttribute.length) &&
            (initialAmountOfAttributes == CIDsForEachAttribute.length),
            "HugoNFT::disproportion in provided attributes and traits data"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(NFT_ADMIN_ROLE, _msgSender());

        _baseTokenURI = baseTokenURI;
        attributesAmount = initialAmountOfAttributes;
        nftGenerationScripts.push(Script(script, true));

        // Very important to set them in constructor,
        // because otherwise contract should be paused until all
        // attributes have their traits set
        for (uint256 i = 0; i < initialAmountOfAttributes; i++) {
            addTraits(
                i,
                traitAmountForEachAttribute[i],
                traitNamesForEachAttribute[i],
                raritiesForEachAttribute[i],
                CIDsForEachAttribute[i]
            );
        }
    }

    function getCIDsOfAttribute(uint256 attributeId)
        external
        view
        returns (string[] memory)
    {
        require(attributeId < attributesAmount, "HugoNFT::invalid attribute id");
        return _CIDsOfAttribute[attributeId];
    }

    function getTraitsOfAttribute(uint256 attributeId)
        external
        view
        returns (Trait[] memory)
    {
        require(attributeId < attributesAmount, "HugoNFT::invalid attribute id");
        return _traitsOfAttribute[attributeId];
    }

    /**
     * @dev Gets tokens owned by the `account`.
     *
     * *Warning*. Never call on-chain. Call only using web3 "call" method!
     */
    function tokenIdsOfOwner(address account)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenAmount = balanceOf(account);
        if (tokenAmount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory output = new uint256[](tokenAmount);
            for (uint256 index = 0; index < tokenAmount; index++) {
                output[index] = tokenOfOwnerByIndex(account, index);
            }
            return output;
        }
    }

    // Check is done by minter only for seeds with an actual amount of attributes.
    // Therefore for attributes amount of 5 valid seeds like [1,2,3,4] or [1,2,3,4,0]
    // will cause revert
    // todo discuss and look at todo in minter
    function isUsedSeed(uint256[] calldata seed) external view returns (bool) {
        require(_isValidSeed(seed), "HugoNFT::an invalid seed was provided");
        return _isUsedSeed[_getSeedHash(seed)];
    }

    // todo discuss, should fail or return empty one
    // if fail add require(_tokenExists(tokenId), "HugoNFT::nft with such id doesn't exist");
    // and change 116 only to _isIdOfGeneratedNFT(tokenId))
    function getNFT(uint256 tokenId)
        external
        view
        returns (NFT memory)
    {
        NFT memory retNFT = _NFTs[tokenId];
        // first check is for nft existence
        if (tokenId == retNFT.tokenId && _isIdOfGeneratedNFT(tokenId)) {
            retNFT.seed = _standardizeSeed(retNFT.seed);
        }
        return retNFT;
    }

    function traitIpfsPath(uint256 attributeId, uint256 traitId)
        external
        view
        returns (string memory)
    {
        require(attributeId < attributesAmount, "HugoNFT::invalid attribute id");
        require(
            traitId != 0,
            "HugoNFT::0 trait id is reserved for 'no attribute' in seed"
        );
        require(
            traitId <= _traitsOfAttribute[attributeId].length,
            "HugoNFT::trait id doesn't exist for the attribute"
        );

        string[] memory lastCIDs = validCIDs();
        string memory attributeCID = lastCIDs[attributeId];
        return string(abi.encodePacked("ipfs://", attributeCID, "/", traitId.toString()));
    }

    function validCIDs() public view returns (string[] memory) {
        string[] memory retCIDs = new string[](attributesAmount);
        for (uint256 i = 0; i < attributesAmount; i++) {
            string[] storage aCIDs = _CIDsOfAttribute[i];
            // Length 0 is impossible, because from the deployment
            // NFT has CIDs for its attributes
            string storage lastCID = aCIDs[aCIDs.length - 1];
            retCIDs[i] = lastCID;
        }
        return retCIDs;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _standardizeSeed(uint256[] memory seed)
        private
        view
        returns (uint256[] memory)
    {
        if (seed.length == attributesAmount) return seed;
        uint256[] memory standardizedSeed = new uint256[](attributesAmount);
        for (uint256 i = 0; i < attributesAmount; i++) {
            standardizedSeed[i] = i > seed.length - 1 ? 0 : seed[i];
        }
        return standardizedSeed;
    }
}