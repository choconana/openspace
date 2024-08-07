// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract MultisigWallet is EIP712("MultisigWallet", "1") {

    bytes32 public constant TRANS_TYPE_HASH = keccak256(
        "Transaction(uint64 id,address to,uint256 value,bytes data)"
    );

    uint8 public constant SIGN_NUM = 2;

    uint64 proposeId;
    Transaction[] txs;
    mapping(uint64 => address) holders;
    mapping(address => bool) owners;

    struct Transaction {
        uint64 id;
        address to;
        uint256 value;
        bytes data;
    }

    event Deposit(address indexed sender, uint amount, uint balance);
    event ExecuteTransaction(
        address indexed to,
        uint value,
        bytes data
    );

    error SignerNotEnough(uint256 amount);
    error PermissionNotEnough();

    constructor(address _owner1, address _owner2, address _owner3) {
        owners[_owner1] = true;
        owners[_owner2] = true;
        owners[_owner3] = true;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function proposeTranscation(address _to,uint _value,bytes memory _data) public returns (uint64) {
        Transaction memory tran = Transaction({
            id: proposeId++,
            to: _to,
            value: _value,
            data: _data
        });
        txs.push(tran);
        holders[tran.id] = msg.sender;
        return tran.id;
    }

    function getTransaction(uint64 idx) public view returns (Transaction memory) {
        return txs[idx];
    }

    function executeTransaction(uint64 idx, bytes[] memory signs) public {
        require(holders[idx] == msg.sender, "no permission to execute");

        uint len = signs.length;
        if (len < SIGN_NUM) {
            revert SignerNotEnough(len);
        }

        Transaction memory tran = txs[idx];
        uint count = 0;
        for (uint i = 0; i < len; i++) {
            if (verify(signs[i], tran)) {
                count++;
            }
        }

        if (count < SIGN_NUM) {
            revert PermissionNotEnough();
        }

        delete txs[idx];
        delete holders[idx];

        (bool success, ) = tran.to.call{value: tran.value}(tran.data);

        require(success, "tx failed");

        emit ExecuteTransaction(tran.to, tran.value, tran.data);

    }

    function verify(bytes memory sign, Transaction memory tran) internal view returns (bool res) {
        res = false;
        bytes32 tranHash = keccak256(abi.encode(TRANS_TYPE_HASH, tran));
        address signer = ECDSA.recover(tranHash, sign);
        if (owners[signer]) {
            res = true;
        }
    }
}