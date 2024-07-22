// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HNFT.sol";
import "./RToken.sol";
import "./IMarket.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket is IMarket, EIP712("NFTMarket", "1") {

    bytes32 public constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    mapping(uint256 => uint256) public tokens;

    mapping(uint256 => address) public buyers;

    mapping(bytes32 => bool) public cancelOrders;

    HNFT hNFT;

    RToken rToken;

    struct NFTOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }


    constructor(address nft, address token) {
        hNFT = HNFT(nft);
        rToken = RToken(token);
    }

    receive() external payable { }
    fallback() external payable { }

    function forSale(bytes memory sellerSign, uint256 tokenId, uint256 amount, uint256 deadline) public returns (bool success) {
        address owner = hNFT.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert NFTOwnerIncorrect(msg.sender, tokenId, owner);
        }
        tokens[tokenId] = amount;

        bytes32 hash = rToken.getERC712Hash(owner, address(this), amount, deadline);
        address signer = ECDSA.recover(hash, sellerSign);
        if (signer != owner) {
            revert InvalidSigner(owner);
        }

        hNFT.setApprovalForAll(msg.sender, address(this), true);

        emit ForSale(owner, tokenId, amount);
        return true;
    }

    function permitBuy(
        bytes memory whiteListUserSign, 
        bytes memory buyerSign, 
        uint256 tokenId, 
        uint256 deadline
    ) public returns (bool success) {
        address buyer = msg.sender;
        address contractOwner = hNFT.owner();
        address nftOwner = hNFT.ownerOf(tokenId);
        uint256 amount = tokens[tokenId];

        require(tokens[tokenId] > 0, "no such nft");

        bytes32 hash = rToken.getERC712Hash(contractOwner, buyer, amount, deadline);
        address whiteUser = ECDSA.recover(hash, whiteListUserSign);
        if (contractOwner != whiteUser) {
            revert InvalidSigner(buyer);
        }
        
        delete tokens[tokenId];
        rToken.permit(buyer, address(this), amount, deadline, buyerSign);

        success =  rToken.transferFrom(buyer, nftOwner, amount);

        buyers[tokenId] = buyer;
        hNFT.safeTransferFrom(nftOwner, buyer, tokenId, abi.encode(amount));

        return success;
    }

    function listOffline(bytes memory sellerSign, NFTOrder memory order) public {
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

    function buyOffline(bytes memory orderSign, NFTOrder memory order) public payable {
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

        if (order.payToken == ETH_FLAG) {
            (bool success,) = order.seller.call{value: order.price}("");
            require(success, "MKT: transfer failed");
        } else {
            SafeERC20.safeTransferFrom(IERC20(order.payToken), buyer, order.seller, order.price);
        }

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
        if (order.nft == address(0) || order.payToken == address(0)) {
            revert InvalidAddress();
        }
    }

    function getCancelOrders(bytes32 orderHash) public view returns (bool) {
        return cancelOrders[orderHash];
    }
}