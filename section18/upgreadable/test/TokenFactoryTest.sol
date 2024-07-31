// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/TokenFactoryV1.sol";
import "../src/TokenFactoryV2.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenFactoryTest is Test {

    TokenFactoryV1 factory1;
    TokenFactoryV2 factory2;

    function setUp() public {
        factory1 = new TokenFactoryV1();
        factory2 = new TokenFactoryV2();
    }

    function test_createTokenV1() public {
        
        uint256 totalSupply = 10e9;
        uint256 perMint = 100;
        address token1 = factory1.deployInscription("R1", totalSupply, perMint);

        assertEq(totalSupply, IERC20(token1).totalSupply());

        factory1.mintInscription(token1);

        assertEq(perMint, IERC20(token1).balanceOf(address(this)));
    }
}