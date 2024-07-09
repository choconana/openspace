// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";
import "./TokenRecipient.sol";

contract TokenBank {

    mapping(address => mapping(address => uint256)) balances;

    event Response(bool success, bytes data);
    event Log(address, uint);

    receive() external payable {
    }
    fallback() external payable {
     }

    function deposit(address tokenAddr, uint256 amt) public {
        (bool success, bytes memory data) = tokenAddr.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amt)
        );
        emit Response(success, data);
    }

    function withdraw(address tokenAddr, uint256 amt) public  {
        (bool success, bytes memory data) = tokenAddr.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amt)
        );
        emit Response(success, data);
    }

    function balanceof(address tokenAddr) public {
        (bool success, bytes memory data) = tokenAddr.call(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );
        emit Response(success, data);
    }

}