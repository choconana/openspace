// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RToken.sol";

contract TokenBank {

    RToken rToken;

    constructor(address tokenAddr) {
        rToken = RToken(tokenAddr);
    }

    event Deposit(address indexed depositor, uint256 amount);

    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) public returns (bool) {
        
        rToken.permit(msg.sender, address(this), amount, deadline, signature);
        
        return deposit(amount);
    }

    function deposit(uint256 amount) public returns (bool) {
        address sender = msg.sender;
        
        bool success = rToken.transferFrom(msg.sender, address(this), amount);
        if (success) {
            emit Deposit(sender, amount);
        }

        return success;
    }

}