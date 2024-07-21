// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketScript is Script {

    NFTMarket public nftMarket;

    function run() external {
         vm.startBroadcast();

        nftMarket = new NFTMarket(0x86a79d123b51A66d276C1339b08AAc4c21bE4DF5, 0xb1509b928482448977501868A07EAff92fFA2387);

        vm.stopBroadcast();
    }
}