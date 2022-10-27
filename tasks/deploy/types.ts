import { BigNumberish } from 'ethers';

export type TaskDeployVRFParams = {
  subId: BigNumberish;
};

export type TaskDeployLotteryParams = {
  token: string;
  lotteryInterval: BigNumberish;
  vrfAddr: string;
};
