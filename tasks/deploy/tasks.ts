import { task, types } from 'hardhat/config';
import '@nomiclabs/hardhat-ethers';

import { logDeployment, preAction } from './funcs';
import { DEPLOY_ERC20, DEPLOY_LOTTERY, DEPLOY_VRF } from './task-names';
import { TaskDeployLotteryParams, TaskDeployVRFParams } from './types';

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

task(DEPLOY_VRF)
  .addParam('subId', 'VRF subscription ID', 0, types.string)
  .setAction(async (params: TaskDeployVRFParams, hre) => {
    await preAction(hre);
    const [deployer] = await hre.ethers.getSigners();

    const factory = await hre.ethers.getContractFactory(
      'LotteryVRFConsumer',
      deployer,
    );

    const lotteryVRFConsumer = await factory.deploy(params.subId);
    await lotteryVRFConsumer.deployed();

    logDeployment(
      'LotteryVRFConsumer',
      ['Address', lotteryVRFConsumer.address],
      ['Deployer', deployer.address],
    );
    return lotteryVRFConsumer.address;
  });

task(DEPLOY_LOTTERY)
  .addParam('token', '', '', types.string)
  .addParam('lotteryInterval', '', 3600, types.int)
  .addParam('vrfAddr', '', '', types.string)
  .setAction(async (params: TaskDeployLotteryParams, hre) => {
    await preAction(hre);
    const [deployer] = await hre.ethers.getSigners();

    const factory = await hre.ethers.getContractFactory('Lottery', deployer);

    const XENToken: string = params.token || (await hre.run(DEPLOY_ERC20));
    const vrfAddr: string = params.vrfAddr || (await hre.run(DEPLOY_VRF));

    const lottery = await factory.deploy(
      XENToken,
      params.lotteryInterval,
      vrfAddr,
    );
    await lottery.deployed();

    logDeployment(
      'Lottery',
      ['Address', lottery.address],
      ['Deployer', deployer.address],
    );
  });
