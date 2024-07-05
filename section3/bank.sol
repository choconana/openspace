// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 合约所有者，用于分配管理员权限
    address private owner;
    // 记录管理员
    mapping(address => bool) admins;
    // 存储储户金额
    mapping(address => uint256) depositors;
    // 记录存款最多的3名用户
    address[3] richests;


    constructor() {
        owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier isAdmin {
        require(admins[msg.sender] == true, "Only admins have the authority");
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

    // 提现
    function withdraw() public isAdmin payable {
        payable(msg.sender).transfer(getBalance());
    }


    // 获取存款金额最多的前3名用户
    function getTop3Richest() public view returns (address[3] memory) {
        return richests;
    }

    receive() external payable {
        require(msg.sender.balance > 0, "the balance should greater than 0");

        address depositor = msg.sender;
        uint amt = msg.value;
        if (depositors[depositor] != 0) {
            // 该储户已存在,增加余额
            depositors[depositor] += amt;
        } else {
            // 记录储户首次操作信息
            depositors[depositor] = amt;
        }
        
        address curUser = depositor;
        uint curAmt = depositors[depositor];
        for (uint i = 0; i < 3; i++) {
            if (curAmt <= depositors[richests[i]]) {
                continue;
            } else {
                curAmt = depositors[richests[i]];

                address tmpUser = curUser;
                curUser = richests[i];
                richests[i] = tmpUser;
            }
        }
    }
    fallback() external payable {}
    
    function getBalance() internal view returns (uint) {
        return address(this).balance;
    }
}