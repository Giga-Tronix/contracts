const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const Web3 = require('web3');
// const JAN_1ST_2030 = 1893456000;
// const ONE_GWEI = 1_000_000_000n;

// module.exports = function () {
const contract = buildModule("TokenPreSaleContract", (m) => {
    const contract = m.contract("TokenPreSale", []);

    m.call(contract, "initialize", [
        m.getParameter('_oracle', '0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE'),
        m.getParameter('_usdt', '0x55d398326f99059ff775485246999027b3197955')
    ]);

    return { contract };

});
// }
module.exports = contract;