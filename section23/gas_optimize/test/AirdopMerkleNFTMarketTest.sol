// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/AirdopMerkleNFTMarket.sol";
import "../src/RToken.sol";
import "../src/HNFT.sol";
import "../src/IMarket.sol";


contract AirdopMerkleNFTMarketTest is Test, IMarket {

    AirdopMerkleNFTMarket market;
    uint256 hNFTPrivateKey;
    RToken rToken;

    HNFT hNFT;

    function setUp() public {
        rToken = new RToken("River", "R");
        (address nftAddr, uint256 pk) = makeAddrAndKey("HZD");
        hNFTPrivateKey = pk;
        vm.prank(nftAddr);
        hNFT = new HNFT("HZD", "H");
        market = new AirdopMerkleNFTMarket(0x55506c7a6262efc758046c9ae4b2174d34945d30762dc7d00443335f887f0f7b, address(hNFT), address(rToken));

        assertEq(nftAddr, hNFT.owner());
    }

    function test_forSale() public {
        uint256 tokenId = 777;
        uint256 price = 100;
        uint256 deadline = 8888;
        (address seller, bytes memory sellerSign) = genSignature("seller1", address(market), price, deadline);


        vm.prank(hNFT.owner());
        mintNFT(seller, tokenId);

        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, tokenId, price);
        
        forSale(sellerSign, tokenId, seller, price, deadline);
    }

    function test_claim() public {
        uint256 tokenId = 777;
        uint256 price = 100;
        uint256 deadline = 77777;
        (address seller, bytes memory sellerSign) = genSignature("seller1", address(market), price, deadline);
        (address buyer, bytes memory buyerSign) = genSignature("buyer1", address(market), price, deadline);

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
        console.log("-------NFT ForSale-------\n  [tokenId:%s] of NFT's price is: ", tokenId, market.tokens(tokenId));



        bytes32[] memory merkleProof = new bytes32[](3);
        merkleProof[0] = 0x1468288056310c82aa4c01a7e12a10f8111a0560e72b700555479031b86c357d;
        merkleProof[1] = 0x40e51f1c845d99162de6c210a9eaff4729f433ac605be8f3cde6d2e0afa44aeb;
        merkleProof[2] = 0xd52688a8f926c816ca1e079067caba944f158e764817b83fc43594370ca9cf62;

        vm.prank(buyer);

        // buyer购买nft
        // market.permitPrePay(buyerSign, tokenId, deadline);
        // market.claimNFT(buyer, tokenId, merkleProof);
        bytes[] memory callData = new bytes[](2);
        callData[0] = abi.encodeWithSelector(AirdopMerkleNFTMarket.permitPrePay.selector, buyerSign, tokenId, deadline);
        callData[1] = abi.encodeWithSelector(AirdopMerkleNFTMarket.claimNFT.selector, buyer, tokenId, merkleProof);
        market.multicall(callData);

        console.log("");
        console.log("-------NFT Trade-------");
        console.log("seller's token balance is: %s\n  buyer's token balance is: %s", rToken.balanceOf(seller), rToken.balanceOf(buyer));
        console.log("tokenId of NFT is: %s and owerOf: %s", tokenId, hNFT.ownerOf(tokenId));
    }

    function forSale(bytes memory sellerSign, uint256 tokenId, address seller,uint256 price, uint256 deadline) public {

        vm.prank(seller);
        market.forSale(sellerSign, tokenId, price, deadline);
        assertEq(price, market.tokens(tokenId));
    }

    function mintNFT(address account, uint256 tokenId) public {
        
        hNFT.mint(account, tokenId);

        assertEq(account, hNFT.ownerOf(tokenId));
    }

    function genSignature(string memory name, address spender, uint256 value, uint256 deadline) public returns (address, bytes memory) {
        (address signer, uint256 privateKey) = makeAddrAndKey(name);
        bytes32 hash = rToken.getERC712Hash(signer, spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return (signer, signature);
    }
}