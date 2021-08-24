//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/** TODO
1. Roles
2. events
3. changeable names and descriptions for NFTs
4. attr hashes - discuss
5. change traits info
*/
contract HugoNFT is ERC721Enumerable {

    enum Rarity{COMMON, UNCOMMON, RARE, LEGENDARY}

    struct Trait {
        uint256 traitId;
        string name;
        Rarity rarity;
        // attribute
    }

    // Script that is used to generate NFTs from traits
    string public nftGenerationScript;

    /**
     * Constants defining attributes ids in {HugoNFT-_traitsOfAttribute} mapping
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
    // tokenId => name
    mapping(uint256 => string) private _tokenName;
    // tokenId => description
    mapping(uint256 => string) private _tokenDescription;
    // attribute => traits of the attribute
    mapping(uint256 => Trait[]) private _traitsOfAttribute;

    uint256 private _attributesAmount;
    string private _baseTokenURI;

    constructor(
        string memory baseTokenURI,
        uint256 attributesAmount,
        string memory script
    )
        ERC721("Hugo", "HUGO")
    {
        require(bytes(baseTokenURI).length > 0, "HugoNFT::empty new URI string provided");
        require(bytes(script).length > 0,"HugoNFT::empty nft generation script provided");
        require(attributesAmount > 0, "HugoNFT::attributes amount is 0");

        _baseTokenURI = baseTokenURI;
        _attributesAmount = attributesAmount;
        nftGenerationScript = script;
    }

    // access by admin and shop
    // check whose beforeTransfer is called
    function mint(
        address to,
        uint256[] calldata seed,
        string memory name,
        string memory description
    )
        external
    {
        require(isValidSeed(seed), "HugoNFT::seed is invalid");
        require(bytes(name).length <= 35, "HugoNFT::too long NFT name");
        require(bytes(description) <= 250, "HugoNFT::too long NFT description");
        require(totalSupply() < supplyCap, "HugoNFT::supply cap was reached");

        uint256 newTokenId = totalSupply();
        super._safeMint(to, newTokenId);

        _tokenSeed[newTokenId] = seed;
        _tokenName[newTokenId] = name;
        _tokenDescription[newTokenId] = description;
    }

    // access by admin only
    // check whose beforeTransfer is called
    // do we need name and description?
    // supplyCap a restriction here as well?
    function mintExclusive(address to) external {
        uint256 newTokenId = totalSupply();
        super._safeMint(to, newTokenId);
    }

    // access by admin only
    function setTokenURI(string calldata newURI) external {
        // check for regex?
        require(bytes(newURI).length > 0, "HugoNFT::empty new URI string provided");
        require(
            keccak256(abi.encodePacked(newURI)) != keccak256(abi.encodePacked(_baseTokenURI)),
            "HugoNFT::can't set same token URI"
        );

        _baseTokenURI = newURI;
    }

    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256[] memory seed
        )
    {
        name = getTokenName(tokenId);
        description = getTokenDescription(tokenId);
        seed = getTokenSeed(tokenId);
    }

    function getTraitsOfAttribute(uint256 attributeId)
        external
        view
        returns(Trait[] memory)
    {
        require(attributeId < _attributesAmount, "HugoNFT::invalid attribute id");
        return _traitsOfAttribute[attributeId];
    }

    /**
     * @dev Gets tokens owned by the `account`.
     *
     * *Warning*. Never call on-chain. Call only using web3 "call" method!
     */
    function tokensOfOwner(address account)
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

    // access
    // call before initialize, otherwise ipfs hash will change
    // provide ID externally?
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

        // This kind of contract has 2 pros:
        // 1. could check whether the id is valid by comparing it with array length
        // 2. trait id also tells about its position in Traits[]
        // But there is a con: we should add traits sequentially
        Trait[] storage traitsOfAttribute = _traitsOfAttribute[attributeId];
        uint256 indexOfTheLastTrait = traitsOfAttribute.length > 0 ?
            traitsOfAttribute.length - 1 : 0;
        Trait storage lastTraitOfAttribute = traitsOfAttribute[indexOfTheLastTrait];

        require(
            lastTraitOfAttribute.traitId + 1 == traitId,
            "HugoNFT::traits should be added sequentially"
        );
        require(bytes(name).length > 0, "HugoNFT::empty trait name");

        Trait[] storage tA = _traitsOfAttribute[attributeId];

        uint256 newTraitId = tA.length;
        Trait memory newTrait = Trait(newTraitId, name, rarity);

        tA.push(newTrait);
    }

    function getTokenSeed(uint256 id) public view returns(uint256[] memory) {
        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
        return _tokenSeed[id];
    }

    function getTokenName(uint256 id) public view returns(string memory) {
        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
        return _tokenName[id];
    }

    function getTokenDescription(uint256 id) public view returns(string memory) {
        require(super.ownerOf(id) != address(0), "HugoNFT::token id doesn't exist");
        return _tokenDescription[id];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // return error
    // ids in seed should follow the "contract" of attributes layout [HEAD_ID, GLASSES_ID, BODY_ID, SHIRT_ID, SCARF_ID]
    function isValidSeed(uint256[] calldata seed) internal view returns (bool) {
        if (seed.length != _attributesAmount) return false;

        for (uint256 i = 0; i < _attributesAmount; i++ ) {
            // if IDs weren't provided sequentially, the only check we could do is
            // by accessing a trait in some mapping, that stores info whether they are
            // present or not.
            uint256 numOfTraits = _traitsOfAttribute[i].length;
            if (seed[i] >= numOfTraits) return false;
        }
        return true;
    }
}