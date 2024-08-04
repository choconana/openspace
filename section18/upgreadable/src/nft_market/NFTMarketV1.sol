// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseERC721.sol";
import "./BaseERC20.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract NFTMarketV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    mapping(uint256 => uint256) public tokens;

    mapping(uint256 => address) public buyers;

    BaseERC721 public nft;
    BaseERC20 public coin;

    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(address nftAddr, address coinAddr, address initialOwner) initializer public {
        nft = BaseERC721(nftAddr);
        coin = BaseERC20(coinAddr);
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function list(uint256 tokenId, uint256 amount) public {
        require(msg.sender == nft.ownerOf(tokenId), "nft owner not right");
        tokens[tokenId] = amount;
    }

    function buyNFT(uint256 tokenId) public {
        address owner = nft.ownerOf(tokenId);
        require(owner != address(0x0), "address incorrect");

        // 卖家支付coin
        bool success = coin.transferFrom(msg.sender, owner, tokens[tokenId]);
        require(success, "pay failed");
        buyers[tokenId] = msg.sender;

        // ntf所有者从买家转为卖家
        nft.transferFrom(owner, msg.sender, tokenId);

        delete tokens[tokenId];
    }

}