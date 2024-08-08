// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    struct NFTOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
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
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        uint256 discountPrice = amount / 2;
        success =  rToken.transferFrom(buyer, nftOwner, discountPrice);

        buyers[tokenId] = buyer;
        hNFT.safeTransferFrom(nftOwner, buyer, tokenId, abi.encode(discountPrice));

        emit Claimed(account, amount);
    }

    function permitPrePay(bytes memory buyerSign, uint256 tokenId, uint256 deadline) public {
        require(tokens[tokenId] > 0, "no such nft");

        address buyer = msg.sender;
        uint256 amount = tokens[tokenId];

        rToken.permit(buyer, address(this), amount, deadline, buyerSign);
    }

    
}