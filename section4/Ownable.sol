// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBank.sol";

contract Ownable {

    // 合约所有者，用于分配管理员权限
    address private owner;
    // 记录管理员
    mapping(address => bool) admins;

    error NotTheOwner();

    error NotTheAdmin();

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { }
    fallback() external payable { }

    modifier isOwner {
        if (msg.sender != owner) {
            revert NotTheOwner();
        }
        _;
    }

    modifier isAdmin {
        if (admins[msg.sender] == false) {
            revert NotTheAdmin();
        }
        _;
    }

    // 添加管理员
    function addAdmin(address addr) public isOwner {
        admins[addr] = true;
    }

    // 删除管理员
    function delAdmin(address addr) public isOwner {
        admins[addr] = false;
    }

    function withdraw(address payable _contract, address payable account) public payable isAdmin {
        IBank(_contract).withdraw(account);
    }
}