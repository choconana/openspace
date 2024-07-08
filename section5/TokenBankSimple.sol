// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "BaseERC20.sol";

contract TokenBankSimple is BaseERC20 {

    // eth兑换token比例
    uint public exchangeRate;

    constructor() {
        exchangeRate = 1000;
    }

    error NumberOverflow();

    modifier amtCheck(uint256 amt) {
        require(amt != 0);
        if (amt > amt * exchangeRate) {
            revert NumberOverflow();
        }
        _;
    }

    receive() external payable { 
        deposit(msg.value);
    }
    fallback() external payable { }

    function deposit(uint256 amt) public amtCheck(amt) returns (bool success) {
        
        uint256 tokenAmt = amt * exchangeRate;
        transferFrom(msg.sender, address(this), tokenAmt);
        return true;
    }

    function withdraw(uint256 amt) public payable amtCheck(amt) returns (bool success) {
        uint256 tokenAmt = amt * exchangeRate;
        transferFrom(address(this), msg.sender, tokenAmt);
        payable(msg.sender).transfer(amt);
        return true;
    }
}