// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/RNT.sol";
import "../src/RNTIDO.sol";

contract IDOTest is Test {

    RNT rnt;

    RNTIDO rntIDO;

    function setUp() public {
        rnt = new RNT("River", "R");
        rntIDO = new RNTIDO(address(rnt));
        
        vm.startPrank(address(rnt));
        rnt.approve(address(rntIDO), rntIDO.MAX_TOTAL_ETH());
        vm.stopPrank();
    }

    function test_presale() public {
        vm.fee(200 ether);
        address partner = makeAddr("Miky");
        (bool success, ) = payable(partner).call{value: 200 ether}("");
        assertTrue(success);
        uint256 amount = 2 * rntIDO.MIN_BUY();

        vm.startPrank(partner);

        rntIDO.presale{value: amount}();
        assertEq(amount, rntIDO.balanceOf());

        vm.stopPrank();
        console.log("pb:", partner.balance);
    }

    function test_presale_end() public {
        address partner = makeAddr("Miky");
        presale_complete(partner, rntIDO.MAX_BUY());
    }

    function test_claim() public {
        address partner = makeAddr("Miky");
        uint256 amount = rntIDO.MIN_BUY();
        presale_complete(partner, amount);

        uint256 rntAmt = rntIDO.PRESALE_AMOUNT() *  amount / address(rntIDO).balance;
        vm.prank(partner);
        rntIDO.claim();

        vm.assertEq(rntAmt, rnt.balanceOf(partner));
    }

    function test_withdraw() public {
        address admin = makeAddr("admin");
        address partner = makeAddr("Miky");
        uint256 amount = rntIDO.MIN_BUY();
        presale_complete(partner, amount);

        rntIDO.withdraw(payable(admin));

        assertEq(rntIDO.MAX_TOTAL_ETH() / 10, admin.balance);
    }

    function test_refund() public {
        vm.fee(300 ether);
        address partner = makeAddr("Jacky");
        uint256 partnerBalance = rntIDO.MAX_BUY();
        (bool success, ) = payable(partner).call{value: partnerBalance}("");
        assertTrue(success);


        vm.prank(partner);
        rntIDO.presale{value: partnerBalance - 1}();

        rntIDO.changeEnd(true);

        vm.prank(partner);
        rntIDO.refund();

        vm.assertEq(partnerBalance, partner.balance);
    }

    function presale_complete(address partner, uint256 amount) public {
        vm.fee(300 ether);
        (bool success, ) = payable(address(rntIDO)).call{value: rntIDO.MAX_TOTAL_ETH() - amount}("");
        assertTrue(success);

        (success, ) = payable(partner).call{value: amount}("");
        assertTrue(success);

        vm.startPrank(partner);

        rntIDO.presale{value: amount}();
        assertEq(amount, rntIDO.balanceOf());

        vm.stopPrank();

        assertTrue(rntIDO.isEnd());
    }
}