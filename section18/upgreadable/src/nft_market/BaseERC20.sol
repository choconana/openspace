// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseERC20 is IERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    error BalanceInsufficient();

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000000000000000000000;
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        // write your code here
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        transferFrom(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success) {
        // write your code here
        require(_value <= totalSupply, "ERC20: transfer amount exceeds balance");
        require(_from != address(0x0), "invalid sender");
        require(_to != address(0x0), "invalid receiver");
        require(balances[_from] >= _value, "balance not enough");
        require(_value != 0 && balances[_to] < balances[_to] + _value, "calculation overflow");
        
        if (msg.sender != _from) {
            require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
            allowances[_from][msg.sender] -= _value;
        }

        _update(_from, _to, _value);
        
        emit Transfer(_from, _to, _value);
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        require(_spender != address(0x0), "invalid spender");
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here     
        return allowances[_owner][_spender];
    }

    function _update(address from, address to, uint256 value) internal {
        if (from == address(0x0)) {
            // 生产token
            balances[to] += value;
            totalSupply += value;
        } else if (to == address(0x0)) {
            // 销毁token
            require(totalSupply >= value, "totalSuppy insufficient");
            balances[to] -= value;
            totalSupply -= value;
        } else {
            balances[from] -= value;
            balances[to] += value;
        }
    }
}