// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RNT.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RNTIDO is Ownable {
    // 总募集ether数量
    uint256 constant public MAX_TOTAL_ETH = 20e20;
    // 募集ether目标数量
    uint256 constant public THRESHOLD = 10e20;
    // 单个RNT价格
    uint256 constant public UNIT_PRICE = 10e12 wei;
    // 最少购买的RNT价格
    uint256 constant public MIN_BUY = 10e14 wei;
    // 最多购买的RNT价格
    uint256 constant public MAX_BUY = 10e15 wei;
    // RNT供应数量
    uint256 constant public PRESALE_AMOUNT = 10e6;
    // 团队分成比例
    uint256 constant public TEAM_SHARING = 10;

    RNT rnt;
    // 用户已募集金额
    mapping(address => uint256) balances;

    bool public isEnd;

    uint256 public totalEth;

    constructor(address _rnt) Ownable(msg.sender) {
        rnt = RNT(_rnt);
    }

    receive() external payable { }
    fallback() external payable { }

    modifier buyCheck() {
        require(msg.value >= MIN_BUY && msg.value <= MAX_BUY, "buy amount invalid");
        _;
    }

    modifier isSuccess() {
        require(isEnd && address(this).balance >= THRESHOLD, "presale success");
        _;
    }

    modifier isFailed() {
        require(isEnd && address(this).balance < THRESHOLD, "presale failed");
        _;
    }

    modifier isActive() {
        require(!isEnd && address(this).balance <= MAX_TOTAL_ETH, "is not active");
        _;
    }

    function presale() public payable buyCheck isActive {
        balances[msg.sender] += msg.value;
        totalEth += msg.value;
        if (address(this).balance >= MAX_TOTAL_ETH) { isEnd = true; }
    }

    function claim() public isSuccess {
        address sender = msg.sender;
        require(balances[sender] > 0, "nothing to claim");
        uint256 rntAmt = PRESALE_AMOUNT *  balances[sender] / totalEth;
        delete balances[sender];
        rnt.transferFrom(address(rnt), sender, rntAmt);
    }

    function withdraw(address payable admin) public isSuccess onlyOwner {
        (bool success, ) = admin.call{value: address(this).balance / TEAM_SHARING}("");
        if (!success) {
            revert();
        }
    }

    function refund() public isFailed {
        address sender = msg.sender;
        uint256 balance = balances[sender];
        require(balance > 0, "nothing to refund");
        delete balances[sender];
        (bool success, ) = payable(sender).call{value: balance}("");
        if (!success) {
            revert();
        }
    }

    // 剩余可预售的ether数量
    function restAmount() public view returns (uint256) {
        return UNIT_PRICE * MAX_TOTAL_ETH - address(this).balance;
    }

    // 预估可获得的RNT数量
    function estimateAmount(uint256 eths) public view returns (uint256) {
        return PRESALE_AMOUNT * eths / (address(this).balance + eths);
    } 

    function changeEnd(bool state) public onlyOwner {
        isEnd = state;
    }

    function balanceOf() public view returns (uint256) {
        return balances[msg.sender];
    }
}