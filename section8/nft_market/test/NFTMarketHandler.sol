// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "lib/forge-std/src/Test.sol";
import "../src/NFTMarket.sol";
import "../src/ExtERC20.sol";
import "../src/BaseERC721.sol";
import "../src/IMarket.sol";

contract NFTMarkeHandler is IMarket, Test {
    ExtERC20 public token;

    BaseERC721 public nft;

    NFTMarket public nftMarket;

    uint256 public price;

    uint256 public tokenId;

    constructor(ExtERC20 _token, BaseERC721 _nft, NFTMarket _nftMarket) {
        token = _token;
        nft = _nft;
        nftMarket = _nftMarket;
    }

    function forSale(address seller, uint256 saleTokenId, uint256 salePrice) public {
        vm.assume(salePrice > 0 && salePrice < 10e5);

        tokenId = saleTokenId;
        price = salePrice;
        vm.prank(seller);
        nftMarket.forSale(tokenId, price);
        assertEq(price, nftMarket.tokens(tokenId));

        vm.prank(seller);
        nft.approve(address(nftMarket), tokenId);
        assertEq(address(nftMarket), nft.getApproved(tokenId));
    }

    function buy(address buyer) public {
        token.transfer(buyer, price);
        token.approve(buyer, price);
        
        assertEq(price, token.allowance(address(this), buyer));
        assertEq(price, token.balanceOf(buyer));

        vm.expectEmit(true, true, false, true);
        emit Buy(buyer, tokenId, price);
        vm.prank(buyer);
        token.transferCallbackWithData(address(nftMarket), price, abi.encode(tokenId));
    }
}