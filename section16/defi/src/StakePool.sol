// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./RNT.sol";
import "./EsRNT.sol";

contract StakePool {

    uint256 constant public MULTIPLER = 10e9;

    uint256 constant public SECOND_PER_DAY = 86400;

    uint256 constant public MAX_RNT = 10e12;

    RNT public immutable rnt;

    EsRNT public immutable esrnt;

    mapping(address => StakeInfo) private stakes;

    struct StakeInfo {
        uint256 staked;
        uint256 unclaimed;
        uint256 lastUpdateTime;
    }

    constructor(address _rnt, address _esrnt) {
        rnt = RNT(_rnt);
        esrnt = EsRNT(_esrnt);
        rnt.approve(_esrnt, MAX_RNT);
    }

    function stake(uint256 amount, uint256 deadline, bytes memory sign) public {
        uint256 now = block.timestamp;
        require(now < deadline, "time expired");
        require(amount > 0, "amount must greater than zero");

        address staker = msg.sender;

        rnt.permit(staker, address(this), amount, deadline, sign);

        StakeInfo memory stakeInfo = stakes[staker];
        uint256 timeDiff = 0;
        if (stakeInfo.lastUpdateTime > 0) {
            timeDiff = now - stakeInfo.lastUpdateTime;
        }
        stakeInfo.unclaimed += stakeInfo.staked * timeDiff / SECOND_PER_DAY;
        stakeInfo.staked += amount;
        stakeInfo.lastUpdateTime = now;

        stakes[staker] = stakeInfo;
    }

    function unstake(uint amount) public {
        require(amount > 0, "amount must greater than zero");

        address staker = msg.sender;
        StakeInfo memory stakeInfo = stakes[staker];
        require(stakeInfo.lastUpdateTime > 0, "nothing to unstake");
        require(stakeInfo.staked > amount, "unstake too many");

        uint256 now = block.timestamp;
        uint256 timeDiff = now - stakeInfo.lastUpdateTime;
        stakeInfo.unclaimed += stakeInfo.staked * timeDiff / SECOND_PER_DAY;
        stakeInfo.staked -= amount;
        stakeInfo.lastUpdateTime = now;

        stakes[staker] = stakeInfo;
    }

    function claim() public {
        address staker = msg.sender;
        uint256 claimAmount = stakes[staker].unclaimed;
        require(claimAmount > 0, "nothing to claim");
        esrnt.mint(staker, claimAmount);
    }

    function stakeOf() public view returns (StakeInfo memory) {
        return stakes[msg.sender];
    }
}