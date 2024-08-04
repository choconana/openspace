// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import "../src/token/TokenTransparentProxy.sol";

contract TokenTransparentProxyScript is Script {

    TokenTransparentProxy public proxy;

    function run() external {
         vm.startBroadcast();

        proxy = new TokenTransparentProxy(address(0x85322A9Af6273b9eA5390A249d52dC51855d589c), address(0xD571Cb930A525c83D7D2B7442a34b09c5F1cCa3E), "");

        vm.stopBroadcast();
    }
}