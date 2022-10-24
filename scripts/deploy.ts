// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';

async function main() {
  console.log('rereasdas');
  // const XENTokenFactory = await ethers.getContractFactory('XENToken');
  // const XENToken = await XENTokenFactory.deploy();
  // await XENToken.deployed();

  const LotteryFactory = await ethers.getContractFactory('Lottery');
  const Lottery = await LotteryFactory.deploy(
    '0x82Fbc13cB7e1046ff9F878E7ddcF1c5190416113',
    900,
  );
  await Lottery.deployed();

  // console.log('XENToken', await XENToken.address);
  console.log('Lottery', await Lottery.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
