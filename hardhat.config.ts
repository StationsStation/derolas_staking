import type { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox-viem';
import '@nomicfoundation/hardhat-foundry';
import * as dotenv from 'dotenv';

dotenv.config();

const baseRpcUrl = process.env.BASE_RPC_URL || process.env.MAINNET_RPC_URL;
if (!baseRpcUrl) throw new Error('BASE_RPC_URL or MAINNET_RPC_URL is not set');

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [
      {
        version: '0.8.30',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.8.24',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.8.20',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: baseRpcUrl,
        blockNumber: 33113700, // Use a block number that exists
      },
      chainId: 8453, // Base mainnet
    },
  },
  paths: {
    sources: './src',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
};

export default config;
