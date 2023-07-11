// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function sleep(ms){
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, ms);
  })
}


async function main() {
  const WinBulk = await ethers.getContractFactory("WinBulk");
  const winBulk = await WinBulk.deploy();

  await winBulk.deployed();

  console.log("WinBulk deployed to:", winBulk.address);

  const WinBulkSale = await ethers.getContractFactory("WinBulkSale");
  const winBulkSale = await upgrades.deployProxy(WinBulkSale, [winBulk.address]);

  await winBulkSale.deployed();

  console.log("WinBulkSale deployed to:", winBulkSale.address);

  // Delay
  await sleep(120 * 1000);

  await hre.run("verify:verify", {
    address: winBulk.address,
    constructorArguments: ["0x246cc531a16103Cd883E1179ae880323D28b31C0"],
  })

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

