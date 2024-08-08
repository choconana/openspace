"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var viem_1 = require("viem");
var merkletreejs_1 = require("merkletreejs");
var users = [
    '0x0000000000000000000000000000000000000001',
    '0x0000000000000000000000000000000000000002',
    '0x0000000000000000000000000000000000000003',
    '0x0000000000000000000000000000000000000004',
    '0x0000000000000000000000000000000000000005',
];
var leaves;
leaves = [];
users.forEach(function (item) {
    leaves.push((0, viem_1.keccak256)((0, viem_1.encodePacked)(['address'], [item])));
});
console.log("leaves: ", leaves);
var merkleTree = new merkletreejs_1.MerkleTree(leaves, viem_1.keccak256);
var root = merkleTree.getHexRoot();
console.log("merkleTree: ", merkleTree);
