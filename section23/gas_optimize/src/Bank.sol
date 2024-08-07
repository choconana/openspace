// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/Test.sol";

contract Bank {
    // 合约所有者，用于分配管理员权限
    address private owner;
    // 记录管理员
    mapping(address => bool) admins;
    
    mapping(address => uint256) public deposits;
    mapping(address => address) _nextDepositors;
    uint256 public listSize;
    address constant public GUARD = address(1);


    constructor() {
        owner = msg.sender;
        _nextDepositors[GUARD] = GUARD;
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

    function deposit(address oldPreDepositor, address newPreDepositor) public payable {
        console.log("deposit:, sender:",deposits[msg.sender], msg.sender);
        if (deposits[msg.sender] == 0 && oldPreDepositor == address(0)) {
            addDepositor(msg.sender, msg.value, newPreDepositor);
        } else {
            increaseScore(msg.sender, msg.value, oldPreDepositor, newPreDepositor);
        }
    }

    // 提现
    function withdraw() public isAdmin payable {
        payable(msg.sender).transfer(getBalance());
    }

    receive() external payable {
    }
    fallback() external payable {}
    
    function getBalance() internal view returns (uint) {
        return address(this).balance;
    }

    function addDepositor(address depositor, uint256 score, address candidateDepositor) public {
        require(_nextDepositors[depositor] == address(0));
        require(_nextDepositors[candidateDepositor] != address(0));
        require(_verifyIndex(candidateDepositor, score, _nextDepositors[candidateDepositor]));
        deposits[depositor] = score;
        _nextDepositors[depositor] = _nextDepositors[candidateDepositor];
        _nextDepositors[candidateDepositor] = depositor;
        listSize++;
    }
  
    function increaseScore(
        address depositor, 
        uint256 score, 
        address oldCandidateDepositor, 
        address newCandidateDepositor
    ) public {
        updateScore(depositor, deposits[depositor] + score, oldCandidateDepositor, newCandidateDepositor);
    }
    
    function reduceScore(
        address depositor, 
        uint256 score, 
        address oldCandidateDepositor, 
        address newCandidateDepositor
    ) public {
        updateScore(depositor, deposits[depositor] - score, oldCandidateDepositor, newCandidateDepositor);
    }
  
    function updateScore(
        address depositor, 
        uint256 newScore, 
        address oldCandidateDepositor, 
        address newCandidateDepositor
    ) public {
        require(_nextDepositors[depositor] != address(0));
        require(_nextDepositors[oldCandidateDepositor] != address(0));
        require(_nextDepositors[newCandidateDepositor] != address(0));
        if(oldCandidateDepositor == newCandidateDepositor) {
            require(_isPrevDepositor(depositor, oldCandidateDepositor));
            require(_verifyIndex(newCandidateDepositor, newScore, _nextDepositors[depositor]));
            deposits[depositor] = newScore;
        } else {
            removeDepositor(depositor, oldCandidateDepositor);
            addDepositor(depositor, newScore, newCandidateDepositor);
        }
    }
  
    function removeDepositor(address depositor, address candidateDepositor) public {
        require(_nextDepositors[depositor] != address(0));
        require(_isPrevDepositor(depositor, candidateDepositor));
        _nextDepositors[candidateDepositor] = _nextDepositors[depositor];
        _nextDepositors[depositor] = address(0);
        deposits[depositor] = 0;
        listSize--;
    }
  
    function getTop(uint256 k) public view returns(address[] memory) {
        require(k <= listSize);
        address[] memory depositorLists = new address[](k);
        address currentAddress = _nextDepositors[GUARD];
        for(uint256 i = 0; i < k; ++i) {
            depositorLists[i] = currentAddress;
            currentAddress = _nextDepositors[currentAddress];
        }
        return depositorLists;
    }
  
  
    function _verifyIndex(
        address prevDepositor, 
        uint256 newValue, 
        address nextDepositor
    ) 
        internal
        view
        returns(bool)
    {
        return (prevDepositor == GUARD || deposits[prevDepositor] >= newValue) && 
            (nextDepositor == GUARD || newValue > deposits[nextDepositor]);
    }
  
    function _isPrevDepositor(address depositor, address prevDepositor) internal view returns(bool) {
        return _nextDepositors[prevDepositor] == depositor;
    }
}