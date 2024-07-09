// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenBank.sol";
import "./TokenRecipient.sol";

contract ExtTokenBank is TokenBank, TokenRecipient {

    function tokenReceived(address account, uint256 amount) external returns (bool success) {
        emit Log(account, amount);
        return true;
    }

    function tokenReceivedWithData(address account, uint256 amount, bytes memory data) external pure returns (bool success) {
        return true;
    }

}