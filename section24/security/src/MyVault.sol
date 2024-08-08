// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyVault {

    address owner;
    constructor(address _owner) {
        owner = _owner;
    }

    receive() external payable {
        if (msg.sender.balance > 0) {
            msg.sender.call(abi.encodeWithSignature("withdraw()", ""));
        }
    }

    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }
}