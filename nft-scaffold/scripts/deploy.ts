import { ethers, upgrades } from "hardhat";

async function main() {

  const maxPerAddressMint = 2;
  const maxPerWhitelistAddressMint = 2;
  const collectionSize = 10000;
  const amountForDevs = 200;
  const amountForWhitelist = 4000;

  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();

  const CodeDoge = await ethers.getContractFactory("CodeDoge");
  const codeDoge = await upgrades.deployProxy(CodeDoge, [maxPerAddressMint, maxPerWhitelistAddressMint, collectionSize, amountForDevs, amountForWhitelist]);

  await codeDoge.deployed();
  console.log(`Deployed to ${codeDoge.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
