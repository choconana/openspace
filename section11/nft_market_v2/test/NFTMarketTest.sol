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
        uint256 price = 100;
        uint256 deadline = 8888;
        (address seller, bytes memory sellerSign) = genSignature("seller1", address(nftMarket), price, deadline);


        vm.prank(hNFT.owner());
        mintNFT(seller, tokenId);

        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, tokenId, price);
        
        forSale(sellerSign, tokenId, seller, price, deadline);
    }

    function test_permitBuy() public {

        uint256 tokenId = 777;
        uint256 price = 100;
        uint256 deadline = 77777;
        (address seller, bytes memory sellerSign) = genSignature("seller1", address(nftMarket), price, deadline);
        (address buyer, bytes memory buyerSign) = genSignature("buyer1", address(nftMarket), price, deadline);

        skip(deadline - 1000);

        // 给seller分发nft
        vm.prank(hNFT.owner());
        mintNFT(seller, tokenId);

        // 给buyer分配token
        vm.prank(address(rToken));
        rToken.transfer(buyer, price);
        assertEq(price, rToken.balanceOf(buyer));

        console.log("-------Init-------\n  seller's address is: %s\n  buyer's address is: %s", seller, buyer);
        console.log("seller's token balance is: %s\n  buyer's token balance is: %s", rToken.balanceOf(seller), rToken.balanceOf(buyer));
        console.log("tokenId of NFT is: %s and owerOf: %s", tokenId, hNFT.ownerOf(tokenId));

        // seller上架nft
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, tokenId, price);
        forSale(sellerSign, tokenId, seller, price, deadline);
        console.log("");
        console.log("-------NFT ForSale-------\n  [tokenId:%s] of NFT's price is: ", tokenId, nftMarket.tokens(tokenId));

        // 给buyer生成白名单签名
        bytes memory whiteListUserSign = genWhiteListSignature(buyer, price, deadline);
        vm.prank(buyer);

        // buyer购买nft
        nftMarket.permitBuy(whiteListUserSign, buyerSign, tokenId, deadline);
        console.log("");
        console.log("-------NFT Trade-------");
        console.log("seller's token balance is: %s\n  buyer's token balance is: %s", rToken.balanceOf(seller), rToken.balanceOf(buyer));
        console.log("tokenId of NFT is: %s and owerOf: %s", tokenId, hNFT.ownerOf(tokenId));
    }

    function mintNFT(address account, uint256 tokenId) public {
        
        hNFT.mint(account, tokenId);

        assertEq(account, hNFT.ownerOf(tokenId));
    }

    // 上架操作
    function forSale(bytes memory sellerSign, uint256 tokenId, address seller,uint256 price, uint256 deadline) public {

        vm.prank(seller);
        nftMarket.forSale(sellerSign, tokenId, price, deadline);
        assertEq(price, nftMarket.tokens(tokenId));
    }

    function genSignature(string memory name, address spender, uint256 value, uint256 deadline) public returns (address, bytes memory) {
        (address signer, uint256 privateKey) = makeAddrAndKey(name);
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