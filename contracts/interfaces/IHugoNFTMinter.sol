//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @dev Main purpose is to provide an interface for front-end dev.
interface IHugoNFTMinter {
    //// ----------------------------------------------- \\\\
    //// ---------------- Minting logic ---------------- \\\\
    //// ----------------------------------------------- \\\\

    // @dev Mints a new auto-generative NFT with a seed for a `to` address.
    function mint(
        address to,
        uint256[] calldata seed,
        string calldata name,
        string calldata description
    )
        external;

    // @dev Mints a new exclusive NFT for a `to` address.
    function mintExclusive(
        address to,
        string calldata name,
        string calldata description,
        string calldata cid
    )
        external;

    // @dev Changes name of the NFT with provided tokenId.
    function changeNFTName(uint256 tokenId, string calldata name)
        external;

    // @dev Changes description of the NFT with provided tokenId.
    function changeNFTDescription(uint256 tokenId, string calldata description)
        external;
}
