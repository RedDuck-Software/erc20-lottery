import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';

import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import {
  getEnvVars,
  getForkNetworkConfig,
  getHardhatNetworkConfig,
  getNetworkConfig,
} from './config';
import './tasks';

dotenv.config();

const { OPTIMIZER, REPORT_GAS, FORKING_NETWORK, COVERAGE, ETHERSCAN_API_KEY } =
  getEnvVars();

if (COVERAGE) {
  require('solidity-coverage');
}

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.4',
        settings: {
          optimizer: {
            enabled: OPTIMIZER,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    main: getNetworkConfig('main'),
    goerli: getNetworkConfig('goerli'),
    hardhat: FORKING_NETWORK
      ? getForkNetworkConfig(FORKING_NETWORK)
      : getHardhatNetworkConfig(),
    local: getNetworkConfig('local'),
    testnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      accounts: [''],
    },
  },
  gasReporter: {
    enabled: REPORT_GAS,
  },
  contractSizer: {
    runOnCompile: OPTIMIZER,
  },
  etherscan: {
    apiKey: 'WQYKKEI2PFSRFZRNQRADZA2JVYV385CYPD',
  },
};

export default config;
