// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingPool {

    event Stake(address indexed staker, uint256 amount);

    event Unstake(address indexed staker, uint256 amount);

    function stake() external payable;

    function unstake(uint256 amount) external;
}