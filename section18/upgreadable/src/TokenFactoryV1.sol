// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TokenImpl.sol";

contract TokenFactoryV1 {

    uint private _perMint;

    constructor() {
        
    }

    function deployInscription(string memory symbol, uint totalSupply, uint perMint) public returns (address) {
        TokenImpl token = new TokenImpl("XToken", symbol, msg.sender);
        token.setTotalSupply(totalSupply, msg.sender);
        _perMint = perMint;
        return address(token);
    }

    function mintInscription(address tokenAddr) public {
        require(_perMint > 0, "_perMint must greater than zero");
        TokenImpl token = TokenImpl(tokenAddr);
        token.mint(msg.sender, _perMint, msg.sender);
    }

    function perMint() public view returns (uint) {
        return _perMint;
    }
}