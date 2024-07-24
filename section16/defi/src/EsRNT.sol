// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./RNT.sol";

contract EsRNT is ERC20 {

    // 兑换时间 30 * 24 * 3600
    uint256 constant public EFFECTIVE_EXCHANGE_TIME = 2592000;

    RNT rnt;

    LockInfo[] locks;

    constructor(string memory _name, string memory _symbol, address _rnt) ERC20(_name, _symbol) {
        rnt = RNT(_rnt);
    }

    struct LockInfo {
        address staker;
        uint256 amount;
        uint256 lockTime;
    }

    function mint(address to, uint256 amount) public {
        require(to != address(0), "invalid address");
        require(amount > 0, "amount must greater than zero");
        rnt.transferFrom(address(rnt), address(this), amount);
        _mint(to, amount);
        LockInfo memory lockInfo = LockInfo({
            staker: to,
            amount: amount,
            lockTime: block.timestamp
        });
        locks.push(lockInfo);
    }

    function burn(uint256 amount) public {
        require(amount > 0, "amount must greater than zero");
        uint256 now = block.timestamp;
        address staker = msg.sender;
        uint256 len = locks.length;
        uint256 profits = 0;
        uint256 burned = 0;
        LockInfo[] memory newLocks = new LockInfo[](len);
        uint256 counter = 0;
        for (uint256 i = 0; i < len; i++) {
            LockInfo memory lockInfo = locks[i];
            if (lockInfo.staker == staker) {
                uint256 profit = lockInfo.amount * (now - lockInfo.lockTime) / EFFECTIVE_EXCHANGE_TIME;
                profits += profit;
                burned += lockInfo.amount - profit;
            } else {
                newLocks[counter] = lockInfo;
                counter++;
            }
        }
        rnt.transferFrom(address(rnt), staker, profits);
        rnt.burn(address(rnt), burned);
        // 防止原数组过大，删除元素后重新调整长度
        delete locks;
        for (uint256 i = 0; i < counter; i++) {
            locks.push(newLocks[i]);
        }
    }
}