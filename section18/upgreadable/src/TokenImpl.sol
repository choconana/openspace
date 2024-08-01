// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenImpl is ERC20 {

    uint256 private _totalSupply;

    address public _owner;

    mapping(address => bool) public admins;
    constructor(string memory name, string memory symbol, address owner) 
        ERC20(name, symbol) 
    {
        _owner = owner;
        admins[owner] = true;
    }

    error Owner(address o1, address o2);

    modifier onlyOwner(address owner) {
        if (_owner != owner) {
            revert Owner(_owner, owner);
        }
        _;
    }

    modifier onlyAdmin(address admin) {
        require(admins[admin], "no permissions");
        _;
    }

    function addAdmin(address admin, address owner) public onlyOwner(owner) {
        admins[admin] = true;
    }

    function setTotalSupply(uint256 totalSupply_, address admin) public onlyAdmin(admin) {
        _totalSupply = totalSupply_;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function mint(address account, uint256 value, address admin) public onlyAdmin(admin) {
        _mint(account, value);
    }

}