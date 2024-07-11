// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarket {
    event ForSale(address indexed seller, uint256 indexed tokenId, uint256 price);

    event Buy(address indexed buyer, uint256 indexed tokenId, uint256 price);

    error AmountIncorrect(address account, uint256 tokenId, uint256 price);
}