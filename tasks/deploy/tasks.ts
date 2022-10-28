import { task, types } from 'hardhat/config';
import '@nomiclabs/hardhat-ethers';

import { logDeployment, preAction } from './funcs';
import { DEPLOY_ERC20, DEPLOY_LOTTERY, DEPLOY_VRF } from './task-names';
import { TaskDeployLotteryParams, TaskDeployVRFParams } from './types';

import { VRF_SUBID } from '../../helpers/constants';

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
  .addParam('subId', 'VRF subscription ID', VRF_SUBID, types.int)
  .setAction(async (params: TaskDeployVRFParams, hre) => {
    await preAction(hre);
    const [deployer] = await hre.ethers.getSigners();

    const factory = await hre.ethers.getContractFactory(
      'LotteryVRFConsumer',
      deployer,
    );

    const lotteryVRFConsumer = await factory.deploy(params.subId);
    console.log(1);
    await lotteryVRFConsumer.deployed();
    console.log(2);

    logDeployment(
      'LotteryVRFConsumer',
      ['Address', lotteryVRFConsumer.address],
      ['Deployer', deployer.address],
    );
    return lotteryVRFConsumer.address;
  });

task(DEPLOY_LOTTERY)
  .addParam(
    'token',
    '',
    '0x1718C874F80204EEB7a82dcdDACA8433203c9001',
    types.string,
  )
  .addParam('lotteryInterval', '', 180, types.int)
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
