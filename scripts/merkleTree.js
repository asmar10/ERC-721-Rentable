const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

const inputs = [
  {
    address: "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    // quantity: 1,
  },
  {
    address: "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    // quantity: 2,
  },
  {
    address: "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
    // quantity: 1,
  },
];

// create leaves from users' address and quantity
const leaves = inputs.map((x) => keccak256(x.address));
const leavesHex = leaves.map((x) => x.toString("hex"));
//console.log("Leaves:", leavesHex)

// create a Merkle tree
const tree = new MerkleTree(leaves, keccak256, { sort: true });
// console.log("Tree:",tree.toString());

//get merkle proofs
const proofs = leaves.map(leave => tree.getHexProof(leave))
// console.log("Proof:",proofs)

//Get root
const root = tree.getHexRoot();
// console.log("root:",root)

module.exports = root