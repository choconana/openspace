// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/RToken.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {

    RToken rToken;

    TokenBank tokenBank;

    event Deposit(address indexed depositor, uint256 amount);

    function setUp() public {
        rToken = new RToken("River", "R");
        tokenBank = new TokenBank(address(rToken));

        console.log(rToken.totalSupply());

    }

    function test_permit(uint256 value, uint256 deadline) public {
        vm.assume(deadline > 1);
        address spender = makeAddr("anybody");

        skip(deadline - 1);

        (address someone, uint256 someonePk) = makeAddrAndKey("someone");
        bytes32 hash = rToken.getERC712Hash(someone, spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(someonePk, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        address signer = ecrecover(hash, v, r, s);
        assertEq(someone, signer);

        rToken.permit(someone, spender, value, deadline, signature);
    }
    
    function test_deposit(uint256 amount, uint256 deadline) public {
        vm.assume(deadline > 1 && amount < 10e12);

        skip(deadline - 1);

        (address alen, uint256 alenPk) = makeAddrAndKey("Alen");
        assignTokens(alen, amount);

        bytes32 hash = rToken.getERC712Hash(alen, address(tokenBank), amount, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alenPk, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(alen);

        vm.expectEmit(true, false, false, true);
        emit Deposit(alen, amount);
        tokenBank.permitDeposit(amount, deadline, signature);

        vm.stopPrank();
    }

    function assignTokens(address user, uint256 amount) internal {
        vm.prank(address(rToken));
        rToken.transfer(user, amount);
        
        vm.assertEq(amount, rToken.balanceOf(user));
    }
}