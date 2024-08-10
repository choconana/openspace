// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import "../src/Bank.sol";

contract BankScript is Script {

    Bank bank;
    function run() external {
         vm.startBroadcast();

        bank = new Bank(0xD571Cb930A525c83D7D2B7442a34b09c5F1cCa3E);

        console.log(address(bank));
        vm.stopBroadcast();
    }
}