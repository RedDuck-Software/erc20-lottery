import { task, types } from 'hardhat/config';
import '@nomiclabs/hardhat-ethers';

import { logDeployment, preAction } from './funcs';
import { DEPLOY_ERC20, DEPLOY_LOTTERY } from './task-names';
import { TaskDeployLotteryParams } from './types';

task(DEPLOY_ERC20).setAction(async (_, hre) => {
  await preAction(hre);
  const [deployer] = await hre.ethers.getSigners();

  const factory = await hre.ethers.getContractFactory('XENToken', deployer);

  const XENToken = await factory.deploy();
  await XENToken.deployed();

  logDeployment(
    'ERC20',
    ['Address', XENToken.address],
    ['Deployer', deployer.address],
  );

  return XENToken.address;
});

task(DEPLOY_LOTTERY)
  .addParam(
    'token',
    '',
    '0xbCA60080cA21Dc4d302C23B38D39B8DC4AAC46Eb',
    types.string,
  )
  .addParam('lotteryInterval', '', 180, types.int)
  .setAction(async (params: TaskDeployLotteryParams, hre) => {
    await preAction(hre);
    const [deployer] = await hre.ethers.getSigners();

    const factory = await hre.ethers.getContractFactory('Lottery', deployer);

    const XENToken: string = params.token || (await hre.run(DEPLOY_ERC20));

    const lottery = await factory.deploy(XENToken, params.lotteryInterval);
    await lottery.deployed();

    logDeployment(
      'Lottery',
      ['Address', lottery.address],
      ['Deployer', deployer.address],
    );
  });
