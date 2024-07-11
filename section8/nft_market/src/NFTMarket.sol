// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC721.sol";
import "./ExtERC20.sol";
import "./TokenRecipient.sol";
import "./IMarket.sol";


contract NFTMarket is IMarket, TokenRecipient {
    
    mapping(uint256 => uint256) public tokens;

    mapping(uint256 => address) public buyers;

    BaseERC721 public nft;
    ExtERC20 public coin;

    constructor(address nftAddr, address coinAddr) {
        nft = BaseERC721(nftAddr);
        coin = ExtERC20(coinAddr);
    }

    // 上架nft
    function forSale(uint256 tokenId, uint256 amount) public {
        if (msg.sender != nft.ownerOf(tokenId)) {
            revert NFTOwnerIncorrect(msg.sender, tokenId, nft.ownerOf(tokenId));
        }

        tokens[tokenId] = amount;
        emit ForSale(msg.sender, tokenId, amount);
    }

    // 购买nft
    function buy(address account, uint256 tokenId, uint256 amount) internal {
        if (amount != tokens[tokenId]) {
            revert AmountIncorrect(account, tokenId, amount);
        }

        address owner = nft.ownerOf(tokenId);
        buyers[tokenId] = account;
        // ntf所有者从买家转为卖家
        nft.transferFrom(owner, account, tokenId);
        emit Buy(account, tokenId, amount);
        
    }

    function tokenReceived(address account, uint256 amount) public pure returns (bool success) {
        return true;
    }

    function tokenReceivedWithData(address account, uint256 amount, bytes memory data) external returns (bool success) {
        require(msg.sender == address(coin), "no authority");
        uint256 tokenId = abi.decode(data, (uint256));
        
        buy(account, tokenId, amount);
        return true;
    }

}