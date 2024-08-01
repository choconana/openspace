// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/TokenFactoryV1.sol";
import "../src/TokenFactoryV2.sol";
import "../src/TokenImpl.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenFactoryTest is Test {

    TokenFactoryV1 factory1;
    TokenFactoryV2 factory2;
    TokenImpl token;

    function setUp() public {
        factory1 = new TokenFactoryV1();
        factory2 = new TokenFactoryV2();
        TokenImpl proto = TokenImpl(factory2.deployInscription("X", 20e9, 200, 5));
        console.log("owner: ", proto._owner());
    }

    function test_createTokenV1() public {
        
        uint256 totalSupply = 10e9;
        uint256 perMint = 100;
        address token1 = factory1.deployInscription("R1", totalSupply, perMint);

        assertEq(totalSupply, IERC20(token1).totalSupply());

        factory1.mintInscription(token1);

        assertEq(perMint, IERC20(token1).balanceOf(address(this)));
    }

    function test_createTokenV2() public {
        uint256 totalSupply = 10e9;
        uint256 perMint = 100;
        uint256 price = 2;
        
        address token2 = factory2.deployInscription("X", totalSupply, perMint, price);
        
        assertEq(totalSupply, IERC20(token2).totalSupply());

        factory2.mintInscription{value: price * perMint}(token2);

        assertEq(perMint, IERC20(token2).balanceOf(address(this)));
    }
}