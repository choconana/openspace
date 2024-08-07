// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract EsRNT {
    struct LockInfo{
        address user;
        uint64 startTime; 
        uint256 amount;
    }
    LockInfo[] private _locks;

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp*2+i), 10e18*(i+1)));
        }
    }

    function readSlot(uint256 index) public view returns (uint256 value) {
        assembly {
            value := sload(index)
        }
    }
}