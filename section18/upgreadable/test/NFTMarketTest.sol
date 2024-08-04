// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../src/nft_market/BaseERC20.sol";
import "../src/nft_market/BaseERC721.sol";
import "../src/nft_market/NFTMarketV1.sol";
import "../src/nft_market/NFTMarketV2.sol";

contract NFTMarketTest is Test {

    BaseERC20 token;
    BaseERC721 nft;
    NFTMarketV1 nftMarketV1;
    NFTMarketV2 nftMarketV2;

    ERC1967Proxy proxy;

    address owner;
    address newOwner;

    function setUp() public {
        
        token = new BaseERC20();
        nft = new BaseERC721("Base", "B", "iii");

        NFTMarketV1 implementation = new NFTMarketV1();

        owner = vm.addr(1);
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (address(nft), address(token), owner)));

        // 用代理关联 MyToken 接口
        nftMarketV1 = NFTMarketV1(address(proxy));
        // Define a new owner address for upgrade tests
        newOwner = address(1);
    }

    function test_listV1() public {
        uint256 tokenId = 777;
        uint256 price = 150;
        nft.mint(address(this), tokenId);
        vm.prank(address(this));
        nftMarketV1.list(tokenId, price);
        vm.assertEq(price, nftMarketV1.tokens(tokenId));
    }

    function testUpgradeability() public {
        NFTMarketV1 implementation = new NFTMarketV1();
        address proxy1 = Upgrades.deployUUPSProxy(
            "NFTMarketV1.sol",
            abi.encodeCall(implementation.initialize, (address(nft), address(token), owner))
        );
        // Upgrade the proxy to a new version; NFTMarketV2
        Upgrades.upgradeProxy(address(proxy1), "NFTMarketV2.sol:NFTMarketV2", "", owner);
        // UnsafeUpgrades.upgradeProxy(address(proxy), implementation, "");
    }
}