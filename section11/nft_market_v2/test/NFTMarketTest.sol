// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/RToken.sol";
import "../src/HNFT.sol";
import "../src/NFTMarket.sol";
import "../src/IMarket.sol";

contract NFTMarketTest is Test, IMarket {

    RToken rToken;

    HNFT hNFT;
    uint256 hNFTPrivateKey;

    NFTMarket nftMarket;

    function setUp() public {
        rToken = new RToken("River", "R");
        (address nftAddr, uint256 pk) = makeAddrAndKey("HZD");
        hNFTPrivateKey = pk;
        vm.prank(nftAddr);
        hNFT = new HNFT("HZD", "H");
        nftMarket = new NFTMarket(address(hNFT), address(rToken));

        assertEq(nftAddr, hNFT.owner());
    }

    function test_forSale() public {
        uint256 tokenId = 777;
        address seller = makeAddr("seller");
        uint256 price = 100;

        vm.prank(hNFT.owner());
        mintNFT(seller, tokenId);

        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, tokenId, price);
        
        forSale(tokenId, seller, price);
    }

    function test_permitBuy() public {

        uint256 tokenId = 777;
        address seller = makeAddr("seller1");
        uint256 price = 100;
        uint256 deadline = 77777;
        (address buyer, bytes memory buyerSign) = genSignature(address(nftMarket), price, deadline);
        console.log("seller: ", seller);
        console.log("buyer: ", buyer);

        skip(deadline - 1000);

        // 给seller分发nft
        vm.prank(hNFT.owner());
        mintNFT(seller, tokenId);

        // 给buyer分配token
        vm.prank(address(rToken));
        rToken.transfer(buyer, price);
        assertEq(price, rToken.balanceOf(buyer));

        // seller上架nft
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, tokenId, price);
        forSale(tokenId, seller, price);

        // 给buyer生成白名单签名
        bytes memory whiteListUserSign = genWhiteListSignature(buyer, price, deadline);
        vm.prank(buyer);

        // buyer购买nft
        nftMarket.permitBuy(whiteListUserSign, buyerSign, tokenId, deadline);
    }

    function mintNFT(address account, uint256 tokenId) public {
        
        hNFT.mint(account, tokenId);

        assertEq(account, hNFT.ownerOf(tokenId));
    }

    // 上架操作
    function forSale(uint256 tokenId, address seller,uint price) public {

        vm.prank(seller);
        nftMarket.forSale(tokenId, price);
        assertEq(price, nftMarket.tokens(tokenId));

        vm.prank(seller);
        hNFT.approve(address(nftMarket), tokenId);
        assertEq(address(nftMarket), hNFT.getApproved(tokenId));
    }

    function genSignature(address spender, uint256 value, uint256 deadline) public returns (address, bytes memory) {
        (address signer, uint256 privateKey) = makeAddrAndKey("signer");
        bytes32 hash = rToken.getERC712Hash(signer, spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return (signer, signature);
    }

    function genWhiteListSignature(address spender, uint256 value, uint256 deadline) public returns (bytes memory signature) {
        bytes32 hash = rToken.getERC712Hash(hNFT.owner(), spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(hNFTPrivateKey, hash);
        signature = abi.encodePacked(r, s, v);

        address signer = ecrecover(hash, v, r, s);
        assertEq(hNFT.owner(), signer);

        vm.prank(hNFT.owner());
        hNFT.addWhiteList(signer);
    }

    function test_sign(uint256 value, uint256 deadline) public {

        genWhiteListSignature(makeAddr("buyer"), value, deadline);
    }
}