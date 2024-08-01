// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HNFT.sol";
import "./IMarket.sol";
import "./IStakingPool.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

// 仅用eth购买
contract NFTMarket is IMarket, IStakingPool, EIP712("NFTMarket", "1") {

    bytes32 public constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    uint public constant FEE_PERCENT = 10000;
    // 费率0.3%
    uint public constant FEE_RATE = 30;

    uint256 public interest_t = FEE_PERCENT;

    uint256 totalEth;

    mapping(bytes32 => bool) public cancelOrders;

    mapping(address => StakeInfo) public stakeInfos;

    HNFT hNFT;

    struct NFTOrder {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 price;
        uint256 deadline;
    }

    struct StakeInfo {
        uint256 principal;
        uint256 interest_i;
    }


    constructor(address nft) {
        hNFT = HNFT(nft);
    }

    event Log(uint256 p1, uint256 p2, uint256 p3);
    event Log1(address a1);

    receive() external payable { }
    fallback() external payable { }

    function list(bytes memory sellerSign, NFTOrder memory order) public {
        _checkOrder(order);

        address seller = msg.sender;
        bytes32 orderHash = keccak256(abi.encode(_LIMIT_ORDER_TYPE_HASH, order));
        address signer = ECDSA.recover(orderHash, sellerSign);
        if (signer != seller) {
            revert InvalidSigner(seller);
        }

        hNFT.setApprovalForAll(seller, address(this), true);

        emit ForSale(seller, order.tokenId, order.price);
    }

    // 离线签名售卖NFT

    function buy(bytes memory orderSign, NFTOrder memory order) public payable {
        _checkOrder(order);

        bytes32 orderHash = keccak256(abi.encode(_LIMIT_ORDER_TYPE_HASH, order));
        address signer = ECDSA.recover(orderHash, orderSign);
        if (signer != order.seller) {
            revert InvalidSigner(msg.sender);
        }
        if (cancelOrders[orderHash]) {
            revert OrderCanceled(orderHash);
        }

        address buyer = msg.sender;
        
        IERC721(order.nft).safeTransferFrom(order.seller, buyer, order.tokenId, "");

        uint fee = order.price * FEE_RATE / FEE_PERCENT;
        uint income = order.price - fee;
        // 计算质押利息
        calInterest(fee);

        (bool success,) = order.seller.call{value: income}("");
        require(success, "MKT: transfer failed");

        emit Buy(buyer, order.tokenId, income);
    }

    function cancelOrder(bytes memory sellerSign, NFTOrder memory order) public {
        bytes32 orderHash = keccak256(abi.encode(_LIMIT_ORDER_TYPE_HASH, order));
        address signer = ECDSA.recover(orderHash, sellerSign);
        if (signer != msg.sender) {
            revert InvalidSigner(msg.sender);
        }
        cancelOrders[orderHash] = true;

        emit Cancel(orderHash);
    }

    function _checkOrder(NFTOrder memory order) private view {
        if (block.timestamp > order.deadline) {
            revert TimeExpired(order.seller, block.timestamp, order.deadline);
        }
        if (order.price == 0) {
            revert AmountIncorrect(order.seller, order.tokenId, order.price);
        }
        if (order.nft == address(0)) {
            revert InvalidAddress();
        }
    }

    function getCancelOrders(bytes32 orderHash) public view returns (bool) {
        return cancelOrders[orderHash];
    }

    function calInterest(uint256 fee) internal {
        require(address(this).balance > 0, "balance must greater than 0");
        interest_t = interest_t * (FEE_PERCENT + fee * FEE_PERCENT / totalEth) / FEE_PERCENT;
        emit Log(interest_t, fee, address(this).balance);
    }

    function stake() payable public {
        uint256 amount = msg.value;
        require(amount > 0, "amount must greater than zero");
        address staker = msg.sender;

        StakeInfo storage stakeInfo = stakeChange(staker);
        stakeInfo.principal += amount;

        totalEth += amount;
        emit Stake(staker, amount);
    }

    function unstake(uint256 amount) public {
        require(amount > 0, "amount must greater than zero");

        address staker = msg.sender;
        StakeInfo storage stakeInfo = stakeChange(staker);

        require(amount <= stakeInfo.principal, "amount too large to unstake");

        stakeInfo.principal -= amount;
        (bool success, ) = payable(staker).call{value: amount}("");
        require(success, "transfer failed");

        emit Unstake(staker, amount);
    }

    function stakeOf() public view returns (uint256) {
        return stakeInfos[msg.sender].principal;
    }

    function stakeChange(address staker) internal returns (StakeInfo storage stakeInfo) {
        stakeInfo = stakeInfos[staker];
        if (stakeInfo.interest_i == 0) {
            stakeInfo.interest_i = FEE_PERCENT;
        }
        // emit Log(stakeInfo.principal, stakeInfo.interest_i, interest_t);

        stakeInfo.principal = stakeInfo.principal * interest_t / stakeInfo.interest_i;
        stakeInfo.interest_i = interest_t;
    }
}