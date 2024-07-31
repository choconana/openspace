// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMarket {
    event ForSale(address indexed seller, uint256 indexed tokenId, uint256 price);

    event Buy(address indexed buyer, uint256 indexed tokenId, uint256 price);

    event Cancel(bytes32 orderHash);

    error AmountIncorrect(address account, uint256 tokenId, uint256 price);

    error NFTOwnerIncorrect(address sender, uint256 tokenId, address owner);

    error InvalidSigner(address sender);

    error TimeExpired(address sender, uint256 currentTime, uint256 deadline);

    error InvalidAddress();

    error OrderCanceled(bytes32 orderHash);
}