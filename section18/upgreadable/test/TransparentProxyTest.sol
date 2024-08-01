// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/TokenFactoryV1.sol";
import "../src/TokenFactoryV2.sol";
import "../src/TokenTransparentProxy.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";


contract TransparentProxyTest is Test {

    TokenFactoryV1 factoryV1;
    TokenFactoryV2 factoryV2;
    TokenTransparentProxy proxy;

    function setUp() public {
        factoryV1 = new TokenFactoryV1();
        factoryV2 = new TokenFactoryV2();
        proxy = new TokenTransparentProxy(address(factoryV1), address(this), "");
    }

    function test_v1() public {
        
        uint256 totalSupply = 10e9;
        uint256 perMint = 100;
        (bool success1, bytes memory data) = address(proxy).call{value: 0}(abi.encodeWithSelector(factoryV1.deployInscription.selector, "R1", totalSupply, perMint));

        address token1 = abi.decode(data, (address));
        assertEq(totalSupply, IERC20(token1).totalSupply());

        (success1, data) = address(proxy).call{value: 0}(abi.encodeWithSelector(factoryV1.mintInscription.selector, token1));

        assertEq(perMint, IERC20(token1).balanceOf(address(this)));
    }

    function test_upgrade() public {
        uint256 totalSupply = 10e9;
        uint256 perMint = 100;
        (bool success, bytes memory data) = address(proxy).call{value: 0}(abi.encodeWithSelector(factoryV1.deployInscription.selector, "R1", totalSupply, perMint));

        address token1 = abi.decode(data, (address));
        assertEq(totalSupply, IERC20(token1).totalSupply());

        (success, data) = address(proxy).call{value: 0}(abi.encodeWithSelector(factoryV1.mintInscription.selector, token1));

        assertEq(perMint, IERC20(token1).balanceOf(address(this)));

        // upgrade
        // 使用proxyAdmin进行升级
        vm.prank(proxy.proxyAdmin());
        (success, data) = address(proxy).call{value: 0}(abi.encodeWithSelector(ITransparentUpgradeableProxy.upgradeToAndCall.selector, address(factoryV2), ""));
        assertTrue(success);

        // 验证升级后状态不变
        (success, data) = address(proxy).call{value: 0}(abi.encodeWithSelector(factoryV2.perMint.selector, ""));
        assertEq(perMint, abi.decode(data, (uint)));

        uint256 price = 2;
        (success, data) = address(proxy).call{value: 0}(abi.encodeWithSelector(factoryV2.deployInscription.selector, "X", totalSupply, perMint, price));
        address token2 = abi.decode(data, (address));

        assertEq(totalSupply, IERC20(token2).totalSupply());

        (success, data) = address(proxy).call{value: price * perMint}(abi.encodeWithSelector(factoryV2.mintInscription.selector, token2));
        assertEq(perMint, IERC20(token2).balanceOf(address(this)));
    }
}