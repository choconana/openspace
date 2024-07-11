// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "lib/forge-std/src/Test.sol";
import "../src/NFTMarket.sol";
import "../src/ExtERC20.sol";
import "../src/BaseERC721.sol";
import "../src/IMarket.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "./NFTMarketHandler.sol";


contract NFTMarketTest is Test, IMarket, IERC721Errors {

    ExtERC20 public token;

    BaseERC721 public nft;

    NFTMarket public nftMarket;

    address public seller;

    address public buyer;

    uint256 tokenId;


    function setUp() public {
        // 初始化token, nft, nftMarket, 卖家
        token = new ExtERC20();
        nft = new BaseERC721("HZD", "H", "ipfs://chocolate");
        nftMarket = new NFTMarket(address(nft), address(token));
        seller = makeAddr("somebody");
        buyer = makeAddr("buyer1");

        // 给买家分配token
        uint256 initAmount = 10e7;
        assginToken(buyer, initAmount);

        // 给卖家分配nft
        tokenId = 777;
        nft.mint(seller, tokenId);
        
        assertEq(seller, nft.ownerOf(tokenId));
        assertEq(1, nft.balanceOf(seller));

        NFTMarkeHandler hanlder = new NFTMarkeHandler(token, nft, nftMarket);
        targetContract(address(hanlder));
    }

    // 上架nft成功测试
    function test_forSale_should_success() public {
        uint256 price = 100;   
        vm.expectEmit(true, true, false, true);
        emit ForSale(seller, tokenId, price);

        forSale(seller, price);
    }

    // 上架nft异常测试
    function test_forSale_should_revert() public {
        uint256 price = 0;   
        address hacker = makeAddr("hacker");
        vm.expectRevert(abi.encodeWithSelector(NFTOwnerIncorrect.selector, hacker, tokenId, seller));

        vm.prank(hacker);
        nftMarket.forSale(tokenId, price);
        
        assertEq(price, nftMarket.tokens(tokenId));
    }

    // 购买nft成功测试
    function test_buy_should_success() public {
        uint256 price = 100;

        forSale(seller, price);

        vm.expectEmit(true, true, false, true);
        emit Buy(buyer, tokenId, price);
        vm.prank(buyer);
        token.transferCallbackWithData(address(nftMarket), price, abi.encode(tokenId));
        
        vm.assertEq(0, token.balanceOf(address(nftMarket)));

    }

    // 卖家购买自己出售的nft
    function test_buy_by_self() public {
        uint256 price = 100;
        forSale(seller, price);

        assginToken(seller, 10e5);

        vm.expectEmit(true, true, false, true);
        emit Buy(seller, tokenId, price);
        vm.prank(seller);
        token.transferCallbackWithData(address(nftMarket), price, abi.encode(tokenId));
    }

    // 不同买家重复购买同一个nft
    function test_buy_duplicately() public {
        uint256 price = 100;
        forSale(seller, price);

        vm.expectEmit(true, true, false, true);
        emit Buy(buyer, tokenId, price);
        vm.prank(buyer);
        token.transferCallbackWithData(address(nftMarket), price, abi.encode(tokenId));
        assertEq(buyer, nft.ownerOf(tokenId));

        address buyer2 = makeAddr("buyer2");
        assginToken(buyer2, 10e5);
        vm.expectRevert(abi.encodeWithSelector(ERC721IncorrectOwner.selector, address(nftMarket), tokenId, buyer));
        vm.prank(buyer2);
        token.transferCallbackWithData(address(nftMarket), price, abi.encode(tokenId));
    }

    // 购买nft金额错误测试
    function testFuzz_buy_with_wrong_token_amount(uint256 buyPrice) public {
        uint256 salePrice = 100;
        vm.assume(buyPrice != salePrice && buyPrice < 10e3 && buyPrice > 0);

        forSale(seller, salePrice);

        vm.expectRevert(abi.encodeWithSelector(AmountIncorrect.selector, buyer, tokenId, buyPrice));
        vm.prank(buyer);
        token.transferCallbackWithData(address(nftMarket), buyPrice, abi.encode(tokenId));
    }

    // 随机购买nft测试
    function testFuzz_trade(address user, uint256 price) public {
        vm.assume(user != address(0x0));
        vm.assume(price >= 1 && price <= 10e6);

        forSale(seller, price);
        assginToken(user, price);

        vm.expectEmit(true, true, false, true);
        emit Buy(user, tokenId, price);
        vm.prank(user);
        token.transferCallbackWithData(address(nftMarket), price, abi.encode(tokenId));
    }

    // nftMarket持仓token不变性测试
    function invariant_nftMarket_cannot_hold_token() public view {
        assertEq(0, token.balanceOf(address(nftMarket)));
    }

    // 分配token
    function assginToken(address account, uint256 amount) internal {
        token.transfer(account, amount);
        token.approve(account, amount);
        
        assertEq(amount, token.allowance(address(this), account));

    }

    // 上架操作
    function forSale(address account,uint price) internal {
        vm.prank(account);
        nftMarket.forSale(tokenId, price);
        assertEq(price, nftMarket.tokens(tokenId));

        vm.prank(account);
        nft.approve(address(nftMarket), tokenId);
        assertEq(address(nftMarket), nft.getApproved(tokenId));
    }
}