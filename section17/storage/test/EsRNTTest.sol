// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/EsRNT.sol";

contract EsRNTTest is Test {

    uint256 constant ADDR = 0xffffffffffffffffffffffffffffffff0000000000000000;
    uint256 constant TIME = 0x00000000000000000000000000000000ffffffffffffffff;

    EsRNT esRNT;

    function setUp() public {
        esRNT = new EsRNT();
    }

    function test_readLocks() public view {
        uint256 value0 = esRNT.readSlot(0);
        console.log("v0:{}", value0);
        bytes32 dataIdx = keccak256(abi.encodePacked(uint256(0)));
        for (uint i = 0; i < value0; i++) {
            uint256 value1 = esRNT.readSlot(uint256(dataIdx) + 2*i);
            console.log("v%s:%s", i, value1);
            console.log("addr%s: %s", i, value1 & ADDR >> 64);
            console.log("time%s: %s", i, value1 & TIME);
            uint256 value2 = esRNT.readSlot(uint256(dataIdx) + 1 + 2*i);
            console.log("amount%s: %s", i, value2);
            console.log("------");
        }
        
    }

    function test_cal() public view {
        uint256 v = 5033042678494780551859081289027804995897870478871072079876;
        console.log(v & ADDR >> 64);
        console.log(v & TIME);
    }
}