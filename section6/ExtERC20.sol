// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";
import "./TokenRecipient.sol";

contract ExtERC20 is BaseERC20 {

    function transferWithCallback(address to, uint256 amount) public returns (bool success){
        approve(to, amount);
        if (isContract(to)) {
            success = TokenRecipient(to).tokenReceived(msg.sender, amount);
            require(success, "No receive message");
        }
        return true;
    }

    function transferWithCallbackWithData(address to, uint256 amount, bytes calldata data) public returns (bool success){
        approve(to, amount);
        if (isContract(to)) {
            success = TokenRecipient(to).tokenReceivedWithData(msg.sender, amount, data);
            require(success, "No receive message");
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}