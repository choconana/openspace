// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenRecipient {
    function tokenReceived(address account, uint256 amount) external returns (bool success);
}