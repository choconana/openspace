// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "../src/MultisigWallet.sol";


contract MultisigWalletTest is Test {

    MultisigWallet wallet;

    address owner1;
    address owner2;
    address owner3;
    mapping(address => uint256) owners;

    error SignerNotEnough(uint256 amount);
    error PermissionNotEnough();

    function setUp() public {
        (address addr, uint256 prv) = makeAddrAndKey("Alice");
        owner1 = addr;
        owners[owner1] = prv;

        (addr, prv) = makeAddrAndKey("Bob");
        owner2 = addr;
        owners[owner2] = prv;

        (addr, prv) = makeAddrAndKey("Cindy");
        owner3 = addr;
        owners[owner3] = prv;

        wallet = new MultisigWallet(owner1, owner2, owner3);
    }

    function test_tx_succcess() public {
        vm.fee(100 ether);
        payable(address(wallet)).transfer(1 ether);

        uint256 amount = 100;
        address to = makeAddr("to");

        uint64 idx = wallet.proposeTranscation(to, amount, "");

        MultisigWallet.Transaction memory tran = wallet.getTransaction(idx);

        bytes memory sign1 = genTranSign(owner1, tran);
        bytes memory sign2 = genTranSign(owner2, tran);

        bytes[] memory signs = new bytes[](2);
        signs[0] = sign1;
        signs[1] = sign2;

        wallet.executeTransaction(idx, signs);

        assertEq(amount, to.balance);
    }

    function test_tx_signer_not_enough() public {
        vm.fee(100 ether);
        payable(address(wallet)).transfer(1 ether);

        uint256 amount = 100;
        address to = makeAddr("to");

        uint64 idx = wallet.proposeTranscation(to, amount, "");

        MultisigWallet.Transaction memory tran = wallet.getTransaction(idx);

        bytes memory sign1 = genTranSign(owner1, tran);

        bytes[] memory signs = new bytes[](1);
        signs[0] = sign1;

        vm.expectRevert();
        // revert SignerNotEnough(1);
        wallet.executeTransaction(idx, signs);

    }

    function test_tx_permission_not_enough() public {
        vm.fee(100 ether);
        payable(address(wallet)).transfer(1 ether);

        uint256 amount = 100;
        address to = makeAddr("to");

        uint64 idx = wallet.proposeTranscation(to, amount, "");

        MultisigWallet.Transaction memory tran = wallet.getTransaction(idx);

        bytes memory sign1 = genTranSign(owner1, tran);

        (address addr, uint256 prv) = makeAddrAndKey("Dave");
        owners[addr] = prv;
        bytes memory sign2 = genTranSign(addr, tran);

        bytes[] memory signs = new bytes[](2);
        signs[0] = sign1;
        signs[1] = sign2;

        vm.expectRevert();
        // revert PermissionNotEnough();
        wallet.executeTransaction(idx, signs);

    }

    function genTranSign(address owner, MultisigWallet.Transaction memory tran) public view returns (bytes memory) {
        bytes32 tranHash = keccak256(abi.encode(wallet.TRANS_TYPE_HASH(), tran));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owners[owner], tranHash);
        return abi.encodePacked(r, s, v);
    }
}