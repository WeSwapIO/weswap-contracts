require('@nomiclabs/hardhat-ethers')
require("@nomiclabs/hardhat-web3")
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    networks: {
        ethereum: {
            url: 'https://eth-mainnet.g.alchemy.com/v2/gAhzVEOdVxVAcav2H2WL0dHCugQMfl1W',
            accounts: [process.env.PK],
        },
        bsc_mainnet: {
            url: 'https://bsc-dataseed3.ninicoin.io',
            chainId: 56,
            accounts: [process.env.PK],
        },
        rinkeby: {
            url: 'https://rinkeby.infura.io/v3/eaa5fb64cc5d4f43aa01d12ead1602f3',
            gas: 2000000,
            // gasPrice: 2000000000,
            accounts: [process.env.PK],
        },
        boba_mainnet: {
            url: 'https://mainnet.boba.network/',
            chainId: 288,
            accounts: [process.env.PK],
        },
        boba_rinkeby: {
            url: 'https://rinkeby.boba.network',
            gas: 5000000,
            gasPrice: 1000000000,
            accounts: [process.env.PK],
        },
        polygon: {
            url: 'https://polygon-rpc.com',
            chainId: 137,
            accounts: [process.env.PK],
        },
    },
    solidity: {
        version: "0.6.12",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
};

