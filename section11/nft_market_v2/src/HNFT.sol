// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HNFT is ERC721, Ownable {

    mapping(address => bool) public whiteList;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {

    }

    function mint(address to, uint256 tokenId) public onlyOwner {

        _safeMint(to, tokenId);
    }
    
    function addWhiteList(address account) public onlyOwner {
        whiteList[account] = true;
    }
}