// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {

    Bank bank;

    function setUp() public {
        bank = new Bank();
    }

    function test_getTop10() public {
        vm.fee(100 ether);

        address depositor1 = makeAddr("depositor1");
        payable(depositor1).transfer(1 ether);
        vm.startPrank(depositor1);
        bank.deposit{value: 500}(address(0), bank.GUARD());
        vm.stopPrank();

        address depositor2 = makeAddr("depositor2");
        payable(depositor2).transfer(1 ether);
        vm.startPrank(depositor2);
        bank.deposit{value: 700}(address(0), bank.GUARD());
        vm.stopPrank();

        address depositor3 = makeAddr("depositor3");
        payable(depositor3).transfer(1 ether);
        vm.startPrank(depositor3);
        bank.deposit{value: 200}(address(0), depositor1);
        vm.stopPrank();

        address depositor4 = makeAddr("depositor4");
        payable(depositor4).transfer(1 ether);
        vm.startPrank(depositor4);
        bank.deposit{value: 300}(address(0), depositor1);
        vm.stopPrank();

        address depositor5 = makeAddr("depositor5");
        payable(depositor5).transfer(1 ether);
        vm.startPrank(depositor5);
        bank.deposit{value: 1000}(address(0), bank.GUARD());
        vm.stopPrank();

        address depositor6 = makeAddr("depositor6");
        payable(depositor6).transfer(1 ether);
        vm.startPrank(depositor6);
        bank.deposit{value: 400}(address(0), depositor1);
        vm.stopPrank();

        address depositor7 = makeAddr("depositor7");
        payable(depositor7).transfer(1 ether);
        vm.startPrank(depositor7);
        bank.deposit{value: 100}(address(0), depositor3);
        vm.stopPrank();

        address depositor8 = makeAddr("depositor8");
        payable(depositor8).transfer(1 ether);
        vm.startPrank(depositor8);
        bank.deposit{value: 1100}(address(0), bank.GUARD());
        vm.stopPrank();

        address depositor9 = makeAddr("depositor9");
        payable(depositor9).transfer(1 ether);
        vm.startPrank(depositor9);
        bank.deposit{value: 900}(address(0), depositor5);
        vm.stopPrank();

        address depositor10 = makeAddr("depositor10");
        payable(depositor10).transfer(1 ether);
        vm.startPrank(depositor10);
        bank.deposit{value: 600}(address(0), depositor2);
        vm.stopPrank();

        address depositor11 = makeAddr("depositor11");
        payable(depositor11).transfer(1 ether);
        vm.startPrank(depositor11);
        bank.deposit{value: 800}(address(0), depositor9);
        vm.stopPrank();

        address[] memory top10 = bank.getTop(10);
        assertEq(top10[0], depositor8);
        assertEq(top10[1], depositor5);
        assertEq(top10[2], depositor9);
        assertEq(top10[3], depositor11);
        assertEq(top10[4], depositor2);
        assertEq(top10[5], depositor10);
        assertEq(top10[6], depositor1);
        assertEq(top10[7], depositor6);
        assertEq(top10[8], depositor4);
        assertEq(top10[9], depositor3);

        vm.startPrank(depositor7);
        bank.deposit{value: 550}(depositor3, depositor2);
        assertEq(650, bank.deposits(depositor7));
        vm.stopPrank();


        top10 = bank.getTop(10);
        assertEq(top10[0], depositor8);
        assertEq(top10[1], depositor5);
        assertEq(top10[2], depositor9);
        assertEq(top10[3], depositor11);
        assertEq(top10[4], depositor2);
        assertEq(top10[5], depositor7);
        assertEq(top10[6], depositor10);
        assertEq(top10[7], depositor1);
        assertEq(top10[8], depositor6);
        assertEq(top10[9], depositor4);
    }
}