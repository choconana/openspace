// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Token is ERC721, Ownable{
    using Strings for uint256;
    string private baseURI;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_) 
    ERC721(name_, symbol_) Ownable(msg.sender) 
    {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory curbaseURI = _baseURI();
        return bytes(curbaseURI).length > 0 ? string(abi.encodePacked(curbaseURI, tokenId.toString())) : "";
    }
}