// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC721.sol";
import "./ExtERC20.sol";
import "./TokenRecipient.sol";


contract ERC721Market is TokenRecipient {
    
    mapping(uint256 => uint256) public tokens;

    mapping(uint256 => address) public buyers;

    BaseERC721 public nft;
    ExtERC20 public coin;

    constructor(address nftAddr, address coinAddr) {
        nft = BaseERC721(nftAddr);
        coin = ExtERC20(coinAddr);
    }

    function list(uint256 tokenId, uint256 amount) public {
        tokens[tokenId] = amount;
    }

    function buy(address owner, uint256 tokenId, uint256 amount) internal {
        require(amount == tokens[tokenId], "amount incorrect");
    
        // ntf所有者从买家转为卖家
        nft.transferFrom(owner, msg.sender, tokenId);
        
    }

    function tokenReceived(address account, uint256 amount) public returns (bool success) {
        return true;
    }

    function tokenReceivedWithData(address account, uint256 amount, bytes memory data) external returns (bool success) {
        uint256 tokenId = abi.decode(data, (uint256));
        address owner = nft.ownerOf(tokenId);

        require(account == owner, "nft owner incorrect");

        buyers[tokenId] = msg.sender;
        buy(owner, tokenId, amount);
        return true;
    }

}