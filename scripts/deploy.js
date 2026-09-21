const hre = require("hardhat");

// BSC mainnet USDT (BEP20): 0x55d398326f99059fF775485246999027B3197955
// BSC testnet has no canonical USDT address; deploy MockUSDT there for testing.
const USDT_ADDRESS = process.env.USDT_ADDRESS;

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  let usdtAddress = USDT_ADDRESS;
  if (!usdtAddress) {
    console.log("USDT_ADDRESS not set — deploying MockUSDT for testing...");
    const MockUSDT = await hre.ethers.getContractFactory("MockUSDT");
    const mockUsdt = await MockUSDT.deploy();
    await mockUsdt.waitForDeployment();
    usdtAddress = await mockUsdt.getAddress();
    console.log("MockUSDT deployed to:", usdtAddress);
  }

  const Pool = await hre.ethers.getContractFactory("USDTStakingPool");
  const pool = await Pool.deploy(usdtAddress, deployer.address);
  await pool.waitForDeployment();

  console.log("USDTStakingPool deployed to:", await pool.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
