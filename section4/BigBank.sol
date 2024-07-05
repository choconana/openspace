// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bank.sol";

contract BigBank is Bank {

    error DepositNotEnough();

    modifier amtCheck {
        if (msg.value <= 0.01 ether) {
            revert DepositNotEnough();
        }
        _;
    }

    function withdraw(address payable account) external payable isAdmin override {
        account.transfer(address(this).balance);
    }

    receive() external payable amtCheck override {
        deposit();
    }
}