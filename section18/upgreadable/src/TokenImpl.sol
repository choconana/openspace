// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenImpl is ERC20 {

    uint256 private _totalSupply;

    address private _owner;
    constructor(string memory name, string memory symbol, address owner) 
        ERC20(name, symbol) 
    {
        _owner = owner;
    }

    modifier onlyOwner(address owner) {
        require(_owner == owner, "no permissions");
        _;
    }

    function setTotalSupply(uint256 totalSupply_, address owner) public onlyOwner(owner) {
        _totalSupply = totalSupply_;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function mint(address account, uint256 value, address owner) public onlyOwner(owner) {
        _mint(account, value);
    }
}