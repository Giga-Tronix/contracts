require('dotenv').config();
require('hardhat-deploy');
require('@nomicfoundation/hardhat-ignition');
require("@nomicfoundation/hardhat-verify");
require("@nomicfoundation/hardhat-toolbox");
const { PRIVATE_KEY } = process.env;

module.exports = {
    defaultNetwork: 'private',
    networks: {
        private: {
            url: `https://blockchain.servers.web.tr/`,
            accounts: [PRIVATE_KEY],
        },
        bsc: {
            url: `https://bsc-dataseed.binance.org/`,
            accounts: [PRIVATE_KEY],
        },
    },
    solidity: '0.8.26',
    etherscan: {
        // apiKey: '5I77YVZW8S85F8T62Y15N128BE9WQKGVJU',
        apiKey: 'RMI4KGJTH9BRZPT6XA49CG4J292DPJT4ZB',
        customChains: [
            {
                network: "private",
                chainId: 8795,
                urls: {
                    apiURL: "https://explorer.servers.web.tr/api",
                    browserURL: "https://explorer.servers.web.tr/",
                }
            }
        ],
    },
    sourcify: {

        enabled: true,
        // Optional: specify a different Sourcify server
        apiUrl: "https://sourcify.dev/server",
        // Optional: specify a different Sourcify repository
        browserUrl: "https://repo.sourcify.dev",
    }

};
