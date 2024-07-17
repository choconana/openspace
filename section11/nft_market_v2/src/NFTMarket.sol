// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HNFT.sol";
import "./RToken.sol";
import "./IMarket.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";


contract NFTMarket is IMarket {
    mapping(uint256 => uint256) public tokens;

    mapping(uint256 => address) public buyers;

    HNFT hNFT;

    RToken rToken;

    constructor(address nft, address token) {
        hNFT = HNFT(nft);
        rToken = RToken(token);
    }

    function forSale(uint256 tokenId, uint256 amount) public returns (bool success) {
        address owner = hNFT.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert NFTOwnerIncorrect(msg.sender, tokenId, owner);
        }
        tokens[tokenId] = amount;

        emit ForSale(owner, tokenId, amount);
        return true;
    }

    function permitBuy(bytes memory whiteListUserSign, bytes memory buyerSign, uint256 tokenId, uint256 deadline) public returns (bool success) {
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
}