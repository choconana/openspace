// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC721.sol";
import "./BaseERC20.sol";


contract ERC721Market {
    
    mapping(uint256 => uint256) public tokens;

    mapping(uint256 => address) public buyers;

    BaseERC721 public nft;
    BaseERC20 public coin;

    constructor(address nftAddr, address coinAddr) {
        nft = BaseERC721(nftAddr);
        coin = BaseERC20(coinAddr);
    }

    function list(uint256 tokenId, uint256 amount) public {
        tokens[tokenId] = amount;
    }

    function buy(uint256 tokenId, uint256 amount) public {
        require(amount == tokens[tokenId], "amount incorrect");

        address owner = nft.ownerOf(tokenId);
        // 卖家支付coin
        bool success = coin.transferFrom(msg.sender, owner, amount);
        require(success, "pay failed");
        buyers[tokenId] = msg.sender;

        // ntf所有者从买家转为卖家
        nft.transferFrom(owner, msg.sender, tokenId);
        
    }

}