// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {NFTMarket1} from "../src/NFTMarket1.sol";

contract NFTMarket1Script is Script {

    NFTMarket1 public nftMarket;

    function run() external {
         vm.startBroadcast();

        nftMarket = new NFTMarket1();

        vm.stopBroadcast();
    }
}