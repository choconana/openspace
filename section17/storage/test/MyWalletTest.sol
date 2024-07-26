// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/MyWallet.sol";

contract MyWalletTest is Test {

    MyWallet wallet;
    
    function setUp() public {
        wallet = new MyWallet("www");
    }

    function test_readSlot() public view {
        (uint256 v0, uint256 v1, uint256 v2)=wallet.readSlot();
        console.log("v0:{}", v0);
        console.log("v1:{}", v1);
        console.log("v2:{}", address(uint160(v2)));
        assertEq(address(uint160(v2)), address(this));
    }

    function test_readOwner() public view {
        address owner = wallet.readOwner();
        assertEq(address(this), owner);
    }

    function test_setOwner() public {
        address addr = address(0x11);
        wallet.setOwner(addr);
        assertEq(addr, address(uint160(wallet.readSlot(2))));
    }
}