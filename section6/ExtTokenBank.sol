// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenBank.sol";
import "./TokenRecipient.sol";
import "./ExtERC20.sol";

contract ExtTokenBank is TokenBank, TokenRecipient {

    ExtERC20 token;

    constructor(address tokenAddress) {
        token = ExtERC20(tokenAddress);
    }


    function tokenReceived(address account, uint256 amount) external returns (bool success) {
        require(msg.sender == address(token), "no authority");
        emit Log(account, amount);
        return true;
    }

    function tokenReceivedWithData(address account, uint256 amount, bytes memory data) external pure returns (bool success) {
        return true;
    }

}