// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/IStakingPool.sol";
import "../src/HNFT.sol";
import "../src/NFTMarket.sol";
import "../src/IMarket.sol";

contract NFTMarketTest is Test, IMarket {

    event Stake(address indexed staker, uint256 amount);

    event Unstake(address indexed staker, uint256 amount);

    bytes32 public constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    HNFT nft;
    uint256 hNFTPrivateKey;

    NFTMarket market;

    function setUp() public {
        (address nftAddr, uint256 pk) = makeAddrAndKey("HZD");
        hNFTPrivateKey = pk;
        vm.prank(nftAddr);
        nft = new HNFT("HZD", "H");
        market = new NFTMarket(address(nft));

        assertEq(nftAddr, nft.owner());
    }

    function test_list() public {
        NFTMarket.NFTOrder memory order = createOrder(address(0), 777, 150, 8888);
        (address seller, , bytes memory sign) = genOrderSignature("seller1", order);
        
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        market.list(sign, order);

        assertTrue(nft.isApprovedForAll(seller, address(market)));
    }

    function test_buy() public {
        buy(15000 wei, 777, true);
    }

    function test_stake() public {
        uint256 amount = 100;
        address staker = makeStaker("staker1");

        vm.expectEmit(true, false, false, true);
        emit Stake(staker, amount);

        vm.prank(staker);
        market.stake{value: amount}();
    }

    function test_unstake() public {
        // staker1,2,3分别进行ether质押
        uint256 amount1 = 100;
        address staker1 = makeStaker("staker1");
        vm.startPrank(staker1);
        market.stake{value: amount1}();
        assertEq(amount1, market.stakeOf());
        vm.stopPrank();

        uint256 amount2 = 200;
        address staker2 = makeStaker("staker2");
        vm.prank(staker2);
        market.stake{value: amount2}();

        uint256 amount3 = 300;
        address staker3 = makeStaker("staker3");
        vm.prank(staker3);
        market.stake{value: amount3}();

        uint256 amountTotal = amount1 + amount2 + amount3;
        console.log("balance:", address(market).balance);
    
        // 质押完后执行购买操作
        uint256 buyAmt = 15000;
        uint256 fee = buyAmt * market.FEE_RATE() / market.FEE_PERCENT();
        buy(buyAmt, 777, true);
        
        uint256 interest_t = market.FEE_PERCENT() + fee * market.FEE_PERCENT() / amountTotal;
        assertEq(interest_t, market.interest_t());

        // 第二次NFT交易
        buyAmt = 20000;
        fee = buyAmt * market.FEE_RATE() / market.FEE_PERCENT();
        buy(buyAmt, 888, false);
        
        interest_t = interest_t * (market.FEE_PERCENT() + fee * market.FEE_PERCENT() / amountTotal) / market.FEE_PERCENT();
        assertEq(interest_t, market.interest_t());

        // 给market充点钱，防止不够付利息
        payable(market).call{value: 1 ether}("");

        // 取款
        uint256 balance1 = staker1.balance;
        vm.startPrank(staker1);
        market.unstake(amount1 * interest_t / market.FEE_PERCENT());
        assertEq(balance1 + amount1 * interest_t / market.FEE_PERCENT(), staker1.balance);
        vm.stopPrank();

        uint256 balance2 = staker2.balance;
        vm.startPrank(staker2);
        market.unstake(amount2 * interest_t / market.FEE_PERCENT());
        assertEq(balance2 + amount2 * interest_t / market.FEE_PERCENT(), staker2.balance);
        vm.stopPrank();

        uint256 balance3 = staker3.balance;
        vm.startPrank(staker3);
        market.unstake(amount3 * interest_t / market.FEE_PERCENT());
        assertEq(balance3 + amount3 * interest_t / market.FEE_PERCENT(), staker3.balance);
        vm.stopPrank();

    }

    function makeStaker(string memory name) public returns (address staker) {
        staker = makeAddr(name);

        vm.fee(10 ether);
        uint256 stakerBalance = 1 ether;
        (bool success,) = payable(staker).call{value: stakerBalance}("");
        assertTrue(success);
        assertEq(stakerBalance, staker.balance);
    }

    function mintNFT(address account, uint256 tokenId) public {
        
        nft.mint(account, tokenId);

        assertEq(account, nft.ownerOf(tokenId));
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

    function createOrder(address seller, uint256 tokenId, uint256 price, uint256 deadline) public view returns (NFTMarket.NFTOrder memory) {
        return NFTMarket.NFTOrder({
            seller: seller,
            nft: address(nft),
            tokenId: tokenId,
            price: price,
            deadline: deadline
        });
    }

    function buy(uint256 price, uint256 tokenId, bool isCheck) public {
        NFTMarket.NFTOrder memory order = createOrder(address(0), tokenId, price, 8888);
        address buyer = makeAddr("buyerX");
        (address seller, , bytes memory orderSign) = genOrderSignature("sellerX", order);

        // 给buyer添加eth余额
        vm.fee(250 ether);
        uint256 buyerBalance = 200 ether;
        (bool success,) = payable(buyer).call{value: buyerBalance}("");
        assertTrue(success);
        if (isCheck) {
            assertEq(buyerBalance, buyer.balance);
        }
        
        // 给seller分发nft
        vm.prank(nft.owner());
        mintNFT(seller, order.tokenId);

        // 上架nft
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, order.tokenId, order.price);
        vm.prank(seller);
        market.list(orderSign, order);
        assertTrue(nft.isApprovedForAll(seller, address(market)));

        // 购买nft
        uint fee = order.price * market.FEE_RATE() / market.FEE_PERCENT();
        console.log("order: ; fee: ", order.price, fee);

        vm.expectEmit(true, true, false, true);
        emit Buy(buyer, order.tokenId, order.price - fee);
        
        vm.prank(buyer);
        market.buy{value: order.price}(orderSign, order);
        // uint cost = order.price - fee;
        if (isCheck) {
            assertEq(buyerBalance - order.price, buyer.balance);
            assertEq(order.price - fee, seller.balance);
        }
        
    }
}