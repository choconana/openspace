import {toHex, keccak256, encodePacked} from 'viem';
import {MerkleTree} from 'merkletreejs';

const users = [
    '0x0000000000000000000000000000000000000001',
    '0x0000000000000000000000000000000000000002',
    '0x29805Ff5b946e7A7c5871c1Fb071f740f767Cf41',
    '0x0000000000000000000000000000000000000004',
    '0x0000000000000000000000000000000000000005',
    // '0x0000000000000000000000000000000000000006',
    // '0x0000000000000000000000000000000000000007',
    // '0x0000000000000000000000000000000000000008',
    // '0x0000000000000000000000000000000000000009',
];

let leaves: any[];
leaves = [];
users.forEach(item => {
    leaves.push(keccak256(encodePacked(['address'], [item as `0x${string}`])));
});

console.log("leaves: ", leaves);

const merkleTree = new MerkleTree(leaves, keccak256, {sort: true});

const root = merkleTree.getHexRoot();
console.log("root: ", root);

const leaf = leaves[2];
const hexProof = merkleTree.getHexProof(leaf);
console.log("hex proof: ", hexProof);

const proof = merkleTree.getProof(leaf);
// console.log("proof: ", proof);

const res = merkleTree.verify(proof, leaf, root);
console.log("verify: ", res);