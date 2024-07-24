// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/RNT.sol";
import "../src/EsRNT.sol";
import "../src/StakePool.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC2612.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract StakePoolTest is Test, EIP712("River", "1"), Nonces {

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Message(address owner,address spender,uint256 value,uint256 deadline,uint256 nonces)");

    RNT rnt;

    EsRNT esRNT;

    StakePool stakePool;

    function setUp() public {
        rnt = new RNT("River", "R");
        esRNT = new EsRNT("EsRiver", "ER", address(rnt));
        stakePool = new StakePool(address(rnt), address(esRNT));

        vm.startPrank(address(rnt));
        rnt.approve(address(stakePool), stakePool.MAX_RNT());
        rnt.approve(address(esRNT), stakePool.MAX_RNT());
        vm.stopPrank();
    }

    function test_stake() public {
        uint256 amount = 200;
        uint256 deadline = 8888;

        skip(deadline - 1000);
        
        address staker = stake(amount, deadline);

        vm.prank(staker);
        StakePool.StakeInfo memory stakeInfo = stakePool.stakeOf();
        assertEq(amount, stakeInfo.staked);
        assertEq(0, stakeInfo.unclaimed);
    }

    function test_unstake() public {
        uint256 amount = 200;
        uint256 deadline = 8888;
        uint256 time1 = 1000;
        uint256 time2 = 3000;
        skip(time1);

        address staker = stake(amount, deadline);
        vm.prank(staker);
        StakePool.StakeInfo memory stakeInfo = stakePool.stakeOf();
        uint256 oldStaked = stakeInfo.staked;
        assertEq(amount, stakeInfo.staked);
        assertEq(0, stakeInfo.unclaimed);
        console.log(stakeInfo.lastUpdateTime);

        skip(time2);
        vm.startPrank(staker);

        uint256 unstaked = 50;
        stakePool.unstake(unstaked);
        stakeInfo = stakePool.stakeOf();
        console.log(stakeInfo.lastUpdateTime);
        assertEq(amount - unstaked, stakeInfo.staked);
        uint256 expectUnclaimed = oldStaked * time2 / stakePool.SECOND_PER_DAY();
        assertEq(expectUnclaimed, stakeInfo.unclaimed);
        vm.stopPrank();
    }

    function test_claim() public {
        uint256 amount = 200;
        uint256 deadline = 8888;
        uint256 time1 = 1000;
        uint256 time2 = 3000;
        skip(time1);

        address staker = stake(amount, deadline);
        vm.prank(staker);
        StakePool.StakeInfo memory stakeInfo = stakePool.stakeOf();
        uint256 oldStaked = stakeInfo.staked;
        assertEq(amount, stakeInfo.staked);
        assertEq(0, stakeInfo.unclaimed);
        console.log(stakeInfo.lastUpdateTime);

        skip(time2);
        vm.startPrank(staker);

        uint256 unstaked = 50;
        stakePool.unstake(unstaked);
        stakeInfo = stakePool.stakeOf();
        console.log(stakeInfo.lastUpdateTime);
        assertEq(amount - unstaked, stakeInfo.staked);
        uint256 expectUnclaimed = oldStaked * time2 / stakePool.SECOND_PER_DAY();
        assertEq(expectUnclaimed, stakeInfo.unclaimed);

        stakePool.claim();
        assertEq(expectUnclaimed, esRNT.balanceOf(staker));

        vm.stopPrank();
    }

    function test_burn() public {
        uint256 amount = 200;
        uint256 deadline = 8888;
        uint256 time1 = 1000;
        uint256 time2 = 3000;
        skip(time1);

        address staker = stake(amount, deadline);
        vm.prank(staker);
        StakePool.StakeInfo memory stakeInfo = stakePool.stakeOf();
        uint256 oldStaked = stakeInfo.staked;
        assertEq(amount, stakeInfo.staked);
        assertEq(0, stakeInfo.unclaimed);
        console.log(stakeInfo.lastUpdateTime);

        skip(time2);
        vm.startPrank(staker);

        uint256 unstaked = 50;
        stakePool.unstake(unstaked);
        stakeInfo = stakePool.stakeOf();
        console.log(stakeInfo.lastUpdateTime);
        assertEq(amount - unstaked, stakeInfo.staked);
        uint256 expectUnclaimed = oldStaked * time2 / stakePool.SECOND_PER_DAY();
        assertEq(expectUnclaimed, stakeInfo.unclaimed);

        stakePool.claim();
        assertEq(expectUnclaimed, esRNT.balanceOf(staker));

        skip(esRNT.EFFECTIVE_EXCHANGE_TIME());

        esRNT.burn(expectUnclaimed);
        assertEq(expectUnclaimed, rnt.balanceOf(staker));

        vm.stopPrank();
    }

    function stake(uint256 amount, uint256 deadline) public returns (address) {
        (address staker, uint256 pk) = makeAddrAndKey("staker1");
        

        RNT.Message memory message = RNT.Message({
            owner: staker,
            spender: address(stakePool),
            value: amount,
            deadline: deadline
        });

        bytes32 digest = keccak256(abi.encode(PERMIT_TYPEHASH, message, nonces(staker)));
        
        bytes32 hash = rnt.eip712Hash(digest); // 需要用验签合约实例化的hash方法

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hash);
        bytes memory sign = abi.encodePacked(r, s, v);
       
        address signer = ECDSA.recover(hash, sign);
        assertEq(staker, signer);
            
        vm.startPrank(staker);

        stakePool.stake(amount, deadline, sign);

        assertEq(amount, stakePool.stakeOf().staked);
        assertEq(0, stakePool.stakeOf().unclaimed);
        vm.stopPrank();

        return staker;
    }
}