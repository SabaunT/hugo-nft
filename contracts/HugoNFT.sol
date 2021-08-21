//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/** TODO
1. Roles
2. events
*/
contract HugoNFT is ERC721 {
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("Hugo", "HUGO") {
        require(bytes(baseTokenURI).length > 0, "HugoNFT::empty new URI string provided");

        _baseTokenURI = baseTokenURI;
    }

    // access by admin only
    function setTokenURI(string calldata newURI) external {
        // check for regex?
        require(bytes(newURI).length > 0, "HugoNFT::empty new URI string provided");
        require(keccak256(abi.encodePacked(newURI)) != keccak256(abi.encodePacked(_baseTokenURI)), "HugoNFT::can't set same token URI");

        _baseTokenURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}