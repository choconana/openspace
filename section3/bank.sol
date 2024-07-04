// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 合约所有者，用于分配管理员权限
    address private owner;
    // 记录管理员
    mapping(address => bool) admins;
    // 存储储户金额
    mapping(address => uint256) depositors;
    // 用于遍历depositors
    address[] depositorsIndex;
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

    modifier sort {
        _;
        topN(3);
    }

    // 添加管理员
    function addAdmin(address addr) public isOwner {
        admins[addr] = true;
    }

    // 删除管理员
    function delAdmin(address addr) public isOwner {
        admins[addr] = false;
    }

    // 存款
    function deposit() public sort payable {
        require(msg.sender.balance > 0, "the balance should greater than 0");

        address depositor = msg.sender;
        uint amt = msg.value;
        if (depositors[depositor] != 0) {
            // 该储户已存在,增加余额
            depositors[depositor] += amt;
        } else {
            // 记录储户首次操作信息
            depositors[depositor] = amt;
            depositorsIndex.push(depositor);
        }
    }

    // 提现
    function withdraw() public isAdmin payable returns (bool) {
        return withdraw2Addr(payable(msg.sender));
    }

    // 提现到指定账户
    function withdraw2Addr(address payable addr) public isAdmin payable returns (bool) {
        
        addr.transfer(getBalance());

        // 提现成功再扣除存款余额
        uint len = depositorsIndex.length;
        for (uint i = 0; i < len; i++) {
            address depositor = depositorsIndex[i];
            depositors[depositor] = 0;
        }
        // 清空排序记录
        delete richests;
        return true;
    }

    // 根据存款金额对用户进行排序
    function topN(uint n) internal {
        delete richests;
        address[] memory copyArr = depositorsIndex;
        uint len = copyArr.length;
        address zeroAddr = address(0x0);
        for (uint i = 0; i < n; i++) {
            uint256 maxAmt = 0;
            uint maxIndex = 0;
            for (uint j = 0; j < len; j++) {
                address richest = copyArr[j];
                if (zeroAddr == richest) {
                    continue;
                }
                if (depositors[richest] >= maxAmt) {
                    maxAmt = depositors[richest];
                    richests[i] = richest;
                    maxIndex = j;
                }
            }
            copyArr[maxIndex] = address(zeroAddr);
        }
    }

    // 获取存款金额最多的前3名用户
    function getTop3Richest() public view returns (address[3] memory) {
        return richests;
    }

    // 用户获取自己存款金额
    function getSelfBalance() public view returns (uint) {
        return depositors[msg.sender];
    }

    receive() external payable {}
    fallback() external payable {}
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}