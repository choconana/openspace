// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;
    address public owner;

    modifier auth {
        require (msg.sender == owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    } 

    function transferOwernship(address _addr) public auth {
        require(_addr!=address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        owner = _addr;
    }

    function readSlot() public view auth returns (uint256 value, uint256 value1, uint256 value2) {

        assembly {
            value := sload(0)
            value1 := sload(1)
            value2 := sload(2)
        }
    }

    function readSlot(uint256 slot) public view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }

    function storeSlot(uint256 slot, uint256 value) public auth {
        assembly {
            sstore(slot, value)
        }
    }

    function setOwner(address addr) public auth {
        require(addr!=address(0), "New owner is the zero address");
        require(owner != addr, "New owner is the same as the old owner");
        uint160 value = uint160(addr);
        assembly {
            sstore(2, value)
        }
    }

    function readOwner() public view returns (address) {
        uint256 value;
        assembly {
            value := sload(2)
        }
        return address(uint160(value));
    }
}
