// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {console} from "../lib/forge-std/src/Test.sol";
import {NFTMarketTest} from "./NFTMarketTest.sol";
import "../src/NFTMarket.sol";

contract NFTMarketOfflineTest is NFTMarketTest {

    bytes32 public constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function test_listOffline() public {
        NFTMarket.NFTOrder memory order = createOrder(address(0), 777, address(rToken), 150, 8888);
        (address seller, , bytes memory sign) = genOrderSignature("seller1", order);
        
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        nftMarket.listOffline(sign, order);

        assertTrue(hNFT.isApprovedForAll(seller, address(nftMarket)));
    }

    function test_listOfflineFlow() public {
        NFTMarket.NFTOrder memory order = createOrder(address(0), 777, address(rToken), 150, 8888);
        (address seller, uint256 privateKey, bytes memory sign) = genOrderSignature("seller1", order);
        
        // 第一次上架
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        nftMarket.listOffline(sign, order);
        assertTrue(hNFT.isApprovedForAll(seller, address(nftMarket)));
        bytes32 orderHash1 = genOrderHash(order);

        // 第二次上架
        order = createOrder(seller, 999, address(rToken), 200, 8888);
        sign = genOrderSignature(privateKey, order);

        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        nftMarket.listOffline(sign, order);
        assertTrue(hNFT.isApprovedForAll(seller, address(nftMarket)));
        bytes32 orderHash2 = genOrderHash(order);

        // 取消第二次上架的订单
        vm.expectEmit(false, false, false, true);
        emit Cancel(genOrderHash(order));
        vm.prank(seller);
        nftMarket.cancelOrder(sign, order);

        assertFalse(nftMarket.getCancelOrders(orderHash1));
        assertTrue(nftMarket.getCancelOrders(orderHash2));
    }

    function test_buyOffline_withToken() public {
        NFTMarket.NFTOrder memory order = createOrder(address(0), 777, address(rToken), 150, 8888);
        (address buyer, ) = genSignature("buyer1", address(nftMarket), order.price, order.deadline);
        (address seller, , bytes memory orderSign) = genOrderSignature("seller1", order);
        
        // 给seller分发nft
        vm.prank(hNFT.owner());
        mintNFT(seller, order.tokenId);

        // 给buyer分配token
        vm.prank(address(rToken));
        rToken.transfer(buyer, order.price);
        assertEq(order.price, rToken.balanceOf(buyer));
        vm.prank(buyer);
        rToken.approve(address(nftMarket), order.price);

        // 上架nft
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        nftMarket.listOffline(orderSign, order);
        assertTrue(hNFT.isApprovedForAll(seller, address(nftMarket)));
        
        // 购买nft
        vm.expectEmit(true, true, false, true);
        emit Buy(buyer, order.tokenId, order.price);
        vm.prank(buyer);
        nftMarket.buyOffline(orderSign, order);

        assertEq(1, hNFT.balanceOf(buyer));
        assertEq(order.price, rToken.balanceOf(seller));
    }

    function test_buyOffline_withEth() public {
        NFTMarket.NFTOrder memory order = createOrder(address(0), 777, ETH_FLAG, 150 wei, 8888);
        (address buyer, ) = genSignature("buyer1", address(nftMarket), order.price, order.deadline);
        (address seller, , bytes memory orderSign) = genOrderSignature("seller1", order);

        vm.fee(250 ether);
        uint256 buyerBalance = 200 ether;
        (bool success,) = payable(buyer).call{value: buyerBalance}("");
        assertTrue(success);
        assertEq(buyerBalance, buyer.balance);
        
        // 给seller分发nft
        vm.prank(hNFT.owner());
        mintNFT(seller, order.tokenId);

        // 上架nft
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        nftMarket.listOffline(orderSign, order);
        assertTrue(hNFT.isApprovedForAll(seller, address(nftMarket)));

        // 购买nft
        vm.expectEmit(true, true, false, true);
        emit Buy(buyer, order.tokenId, order.price);
        
        vm.prank(buyer);
        nftMarket.buyOffline{value: order.price}(orderSign, order);
        assertEq(buyerBalance - order.price, buyer.balance);
        assertEq(order.price, seller.balance);
    }

    function createOrder(address seller, uint256 tokenId, address payToken, uint256 price, uint256 deadline) public view returns (NFTMarket.NFTOrder memory) {
        return NFTMarket.NFTOrder({
            seller: seller,
            nft: address(hNFT),
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadline: deadline
        });
    }

    function genOrderSignature(string memory name, NFTMarket.NFTOrder memory order) public returns (address, uint256, bytes memory) {
        (address signer, uint256 privateKey) = makeAddrAndKey(name);
        order.seller = signer;
        bytes32 orderHash = genOrderHash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, orderHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return (signer, privateKey, signature);
    }

    function genOrderSignature(uint256 privateKey, NFTMarket.NFTOrder memory order) public pure returns (bytes memory) {
        bytes32 orderHash = genOrderHash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, orderHash);
        return abi.encodePacked(r, s, v);
    }

    function genOrderHash(NFTMarket.NFTOrder memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(_LIMIT_ORDER_TYPE_HASH, order));
    }
}