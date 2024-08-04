// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Script} from "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";
import "../src/nft_market/NFTMarketV1.sol";
import "../src/nft_market/NFTMarketV2.sol";
import "../src/nft_market/BaseERC20.sol";
import "../src/nft_market/BaseERC721.sol";

contract DeployMarketImplementation is Script {
    function run() public {
        // Use address provided in config to broadcast transactions
        vm.startBroadcast();
        // Deploy the nft market
        // NFTMarketV1 implementation = new NFTMarketV1();
        NFTMarketV2 implementation = new NFTMarketV2();
        // Deploy the token
        // BaseERC20 token = new BaseERC20();
        // Deploy the nft
        // BaseERC721 nft = new BaseERC721("Base", "B", "iii");
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
        // Log the token address
        console.log("Market Implementation Address:", address(implementation));
        // console.log("Token Address:", address(token));
        // console.log("NFT Implementation Address:", address(nft));
    }
}