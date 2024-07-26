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

    function mint(address to, uint256 amount) public returns (uint256) {
        require(to != address(0), "invalid address");
        require(amount > 0, "amount must greater than zero");
        rnt.transferFrom(msg.sender, address(this), amount);
        _mint(to, amount);
        LockInfo memory lockInfo = LockInfo({
            staker: to,
            amount: amount,
            lockTime: block.timestamp
        });
        locks.push(lockInfo);
        return locks.length - 1;
    }

    function burn(uint256 idx) public {
        require(idx >=0, "idx must greater or equal than zero");
        uint256 now = block.timestamp;
        address staker = msg.sender;

        LockInfo storage lockInfo = locks[idx];

        require(staker == lockInfo.staker, "no permission to burn");

        uint256 profit = lockInfo.amount * (now - lockInfo.lockTime) / EFFECTIVE_EXCHANGE_TIME;
        uint256 burned = lockInfo.amount - profit;

        delete locks[idx];

        rnt.transferFrom(address(rnt), staker, profit);
        rnt.burn(address(rnt), burned);

    }
}