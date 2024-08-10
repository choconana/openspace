// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {

    Bank bank;

    function setUp() public {
        bank = new Bank(makeAddr("feeTo"));
    }

    function test_task() public {
        console.log(bank.THRESHOLD());

        vm.fee(1 ether);
        // bank.deposit{value: 500}();
        payable(address(bank)).call{value: 500}(abi.encodePacked(keccak256("deposit()")));
        assertEq(500, address(bank).balance);

        bank.deposit{value: 600}();
        bank.performUpkeep("");
        assertEq(550, address(bank).balance);
        assertEq(550, bank.feeTo().balance);

    }
}