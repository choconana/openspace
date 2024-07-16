// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC2612.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract RToken is ERC20, EIP712, Nonces {

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) EIP712(_name, "1") {
        _mint(address(this), 10e18);
    }

    error ExecutionsExpired(address sender, uint256 deadline, uint256 currentTime);

    error SignatureVerifyFailed(address toSign, address signer);

    event PermissionEvent(address indexed sender, address indexed signer, uint256 value);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes memory signature
    ) public {
        if (deadline < block.timestamp) {
            revert ExecutionsExpired(msg.sender, deadline, block.timestamp);
        }

        bytes32 hash = getERC712Hash(owner, spender, value, deadline);

        address signer = ECDSA.recover(hash, signature);

        if (signer != owner) {
            revert SignatureVerifyFailed(owner, signer);
        }

        _approve(owner, spender, value);

        emit PermissionEvent(msg.sender, signer, value);
    }

    function nonces(address owner) public view override returns (uint256) {
        return super.nonces(owner);
    }


    function getERC712Hash(address owner, address spender, uint256 value, uint256 deadline) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces(owner), deadline));

        return EIP712._hashTypedDataV4(structHash);
    }
}