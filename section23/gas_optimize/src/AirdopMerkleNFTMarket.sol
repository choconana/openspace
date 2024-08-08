// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./HNFT.sol";
import "./RToken.sol";
import "./IMarket.sol";

contract AirdopMerkleNFTMarket is IMarket {

    bytes32 public immutable merkleRoot;

    bytes32 public constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    HNFT hNFT;

    RToken rToken;

    mapping(uint256 => uint256) public tokens; 
    mapping(uint256 => address) public buyers;

    struct NFTOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    constructor(bytes32 merkleRoot_, address nft, address token) {
        merkleRoot = merkleRoot_;
        hNFT = HNFT(nft);
        rToken = RToken(token);
    }

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

    function claimNFT(
        address account,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) public {
        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "MerkleDistributor: Invalid proof."
        );

        address nftOwner = hNFT.ownerOf(tokenId);
        uint256 discountPrice = tokens[tokenId] / 2;
        bool success =  rToken.transferFrom(account, nftOwner, discountPrice);

        buyers[tokenId] = account;
        hNFT.safeTransferFrom(nftOwner, account, tokenId, abi.encode(discountPrice));

        emit Claimed(account, discountPrice);
    }

    function permitPrePay(bytes memory buyerSign, uint256 tokenId, uint256 deadline) public {
        require(tokens[tokenId] > 0, "no such nft");

        address buyer = msg.sender;
        uint256 amount = tokens[tokenId];

        rToken.permit(buyer, address(this), amount, deadline, buyerSign);
    }

    
}