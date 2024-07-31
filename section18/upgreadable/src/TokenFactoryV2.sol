// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TokenImpl.sol";

contract TokenFactoryV2 {

    uint private _perMint;

    uint private _price;

    constructor() {
        
    }

    function createToken(address impl) public returns (address) {
        return createClone(impl);
    }

    function deployInscription(string memory symbol, uint totalSupply, uint perMint) public returns (address) {
        TokenImpl token = new TokenImpl("XToken", symbol, msg.sender);
        token.setTotalSupply(totalSupply, msg.sender);
        _perMint = perMint;
        return address(token);
    }

    function mintInscription(address tokenAddr) public payable {
        require(_perMint > 0, "_perMint must greater than zero");
        require(_price == msg.value, "incorrect amount");
        TokenImpl token = TokenImpl(tokenAddr);
        token.mint(tokenAddr, _perMint, msg.sender);
    }

    function perMint() public view returns (uint) {
        return _perMint;
    }

    function price() public view returns (uint) {
        return _price;
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target) << 16;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602b80600a3d3981f3363d3d373d3d3d363d71000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x26), 0x5af43d82803e903d91602957fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x35)
        }
    }
}