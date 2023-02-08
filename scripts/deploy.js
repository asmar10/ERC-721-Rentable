
const hre = require("hardhat");
const root = require("./merkleTree")

async function main() {
 
  const supply = 100;
  const URI = "https://thisIsUri/Hidden";
  const merkleRoot = root;

  const Token = await hre.ethers.getContractFactory("token");
  const token = await Token.deploy(supply);
  await token.deployed();

  console.log(`Token Contract deployed with ${supply} supply at address ${token.address}`);

  const Nft = await hre.ethers.getContractFactory("nft");
  const nft = await Nft.deploy(token.address,URI,merkleRoot);
  await nft.deployed();

  console.log(`NFT Contract deployed  at address ${nft.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
