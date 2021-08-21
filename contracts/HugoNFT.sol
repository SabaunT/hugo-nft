//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/** TODO
1. Roles
2. events
*/
contract HugoNFT is ERC721Enumerable {
    struct Trait {
        uint256 traitId;
        string name;
        uint256 rarity;
        // attribute
    }

    // Script that is used to generate NFTs from traits
    string public script;

    /**
     * Constants defining attributes numbers on {HugoNFT-traits} mapping.
     */
    uint256 constant public HEAD_ID = 0;
    uint256 constant public GLASSES_ID = 1;
    uint256 constant public BODY_ID = 2;
    uint256 constant public SHIRT_ID = 3;
    uint256 constant public SCARF_ID = 4;

    // Available to mint amount of NFTs.
    uint256 constant public supplyCap = 10000;

    // tokenId => seed. Seed is an array of trait ids.
    mapping(uint256 => uint256[]) private _tokenSeed;
    // attribute => traits of the attribute
    mapping(uint256 => Trait[]) private _traitsOfAttribute;

    uint256 private _attributesAmount;
    string private _baseTokenURI;

    // rewrite with an initializer pattern
    constructor(string memory baseTokenURI, uint256 attributesAmount) ERC721("Hugo", "HUGO") {
        require(bytes(baseTokenURI).length > 0, "HugoNFT::empty new URI string provided");
        require(attributesAmount > 0, "HugoNFT::attributes amount is 0");

        _baseTokenURI = baseTokenURI;
        _attributesAmount = attributesAmount;
    }

    // access by admin and shop
    // check whose beforeTransfer is called
    function mint(address to, uint256[] calldata seed) external {
        require(isValidSeed(seed), "HugoNFT::seed is invalid");
        uint256 newTokenId = totalSupply();
        super._safeMint(to, newTokenId);
        _tokenSeed[newTokenId] = seed;
    }

    // access by admin only
    function setTokenURI(string calldata newURI) external {
        // check for regex?
        require(bytes(newURI).length > 0, "HugoNFT::empty new URI string provided");
        require(keccak256(abi.encodePacked(newURI)) != keccak256(abi.encodePacked(_baseTokenURI)), "HugoNFT::can't set same token URI");

        _baseTokenURI = newURI;
    }

    function getTokenSeed(uint256 id) external view returns(uint256[] memory) {
        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
        return _tokenSeed[id];
    }

    function getTraitsOfAttribute(uint256 attributeId) external view returns(Trait[] memory) {
        require(attributeId < _attributesAmount, "HugoNFT::invalid attribute id");
        return _traitsOfAttribute[attributeId];
    }

    /**
     * @dev Gets tokens owned by the `account`.
     *
     * *Warning*. Never call on-chain. Call only using web3 "call" method!
     */
    function tokensOfOwner(address account) external view returns (uint256[] memory ownerTokens) {
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

    // access
    // call before initialize, otherwise ipfs hash will change
    function addTrait(uint256 attributeId, string calldata name, uint256 rarity) public {
        require(attributeId < _attributesAmount, "HugoNFT::invalid attribute id");
        require(bytes(name).length > 0, "HugoNFT::empty trait name");
        // check for rarity?
        Trait[] storage tA = _traitsOfAttribute[attributeId];

        uint256 newTraitId = tA.length;
        Trait memory newTrait = Trait(newTraitId, name, rarity);

        tA.push(newTrait);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // return error
    // ids in seed should follow the "contract" of attributes layout [HEAD_ID, GLASSES_ID, BODY_ID, SHIRT_ID, SCARF_ID]
    function isValidSeed(uint256[] calldata seed) internal returns (bool) {
        if (seed.length != _attributesAmount) return false;

        for (uint256 i = 0; i < _attributesAmount; i++ ) {
            uint256 numOfTraits = _traitsOfAttribute[i].length;
            if (seed[i] >= numOfTraits) return false;
        }
        return true;
    }
}