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

        StakeInfo storage stakeInfo = stakes[staker];
        uint256 timeDiff = 0;
        if (stakeInfo.lastUpdateTime > 0) {
            timeDiff = now - stakeInfo.lastUpdateTime;
        }

        unclaim(stakeInfo, timeDiff);
        stakeInfo.staked += amount;
        stakeInfo.lastUpdateTime = now;


        rnt.transferFrom(staker, address(this), amount);
    }

    function unstake(uint amount) public {
        require(amount > 0, "amount must greater than zero");

        address staker = msg.sender;
        StakeInfo storage stakeInfo = stakes[staker];
        require(stakeInfo.lastUpdateTime > 0, "nothing to unstake");
        require(stakeInfo.staked > amount, "unstake too many");

        uint256 now = block.timestamp;
        uint256 timeDiff = now - stakeInfo.lastUpdateTime;

        unclaim(stakeInfo, timeDiff);
        stakeInfo.staked -= amount;
        stakeInfo.lastUpdateTime = now;

        rnt.transfer(staker, amount);
    }

    function claim() public returns (uint256) {
        address staker = msg.sender;
        uint256 claimAmount = stakes[staker].unclaimed;
        require(claimAmount > 0, "nothing to claim");
        stakes[staker].unclaimed = 0;
        return esrnt.mint(staker, claimAmount);
    }

    function unclaim(StakeInfo storage stakeInfo, uint256 timeDiff) private {
        stakeInfo.unclaimed += stakeInfo.staked * timeDiff / SECOND_PER_DAY;
    }

    function stakeOf() public view returns (StakeInfo memory) {
        return stakes[msg.sender];
    }
}