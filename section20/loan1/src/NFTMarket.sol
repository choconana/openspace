// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HNFT.sol";
import "./IMarket.sol";
import "./IStakingPool.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// 仅用eth购买
contract NFTMarket is IMarket, IStakingPool, EIP712("NFTMarket", "1") {

    bytes32 public constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    // 费率0.3%
    uint public constant FEE_RATE = 30;

    uint256 public totalStake;

    mapping(bytes32 => bool) public cancelOrders;

    mapping(address => uint256) private stakes;

    address[] private stakers;

    HNFT hNFT;

    struct NFTOrder {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 price;
        uint256 deadline;
    }


    constructor(address nft) {
        hNFT = HNFT(nft);
    }

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

        uint fee = order.price * FEE_RATE / 10000;

        // 计算质押利息
        calInterest(fee);

        (bool success,) = order.seller.call{value: order.price - fee}("");
        require(success, "MKT: transfer failed");

        emit Buy(buyer, order.tokenId, order.price);
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
        uint len = stakers.length;
        for(uint i = 0; i < len; i++) {
            uint256 stakeAmt = stakes[stakers[i]];
            stakes[stakers[i]] += fee * stakeAmt / totalStake;
        }
        totalStake += fee;
    }

    function stake() payable public {
        uint256 amount = msg.value;
        require(amount > 0, "amount must greater than zero");
        address staker = msg.sender;

        totalStake += amount;
        stakes[staker] += amount;
        stakers.push(staker);

        emit Stake(staker, amount);
    }

    function unstake(uint64 amount) public {
        require(amount > 0, "amount must greater than zero");

        address staker = msg.sender;
        require(amount <= stakes[staker], "amount too large to unstake");

        totalStake -= amount;
        stakes[staker] -= amount;

        emit Unstake(staker, amount);
    }
}