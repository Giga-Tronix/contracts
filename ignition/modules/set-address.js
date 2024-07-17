const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const Web3 = require('web3');

// const JAN_1ST_2030 = 1893456000;
// const ONE_GWEI = 1_000_000_000n;

module.exports = buildModule("TokenPreSalechangeSaleTokenAddress", (m) => {
    // const oracle = m.getParameter("_oracle", '0x514910771AF9Ca656af840dff83E8264EcF986CA');
    // const usdt = m.getParameter("_usdt", '0xaDBCA24D02CF58133B118D032c0f29e1FC3AC46C');

    const contract = m.contractAt("TokenPreSale", '0x8a0BEC963664b9C1200147811f8132E7f4084500');

    // m.call(contract, "createPresale", [
    //     m.getParameter("_startTime", Math.floor(Date.now() / 1000) + 60), // start time in seconds
    //     m.getParameter("_endTime", Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30 * 6), // end time in seconds
    //     m.getParameter("_price", Web3.utils.toWei('0.00003', 'ether')),
    //     m.getParameter("_tokensToSell", Web3.utils.toWei('200000000', 'ether')),
    //     m.getParameter("_baseDecimals", 18),
    //     m.getParameter("_enableBuyWithEth", true),
    //     m.getParameter("_enableBuyWithUsdt", true),
    // ]);
    m.call(contract, "changeSaleTokenAddress", [m.getParameter("_id", 1), m.getParameter("_newAddress", '0x17E1E2e19Ecacc5d5B482C532d419AAd34eAa7Cd')]);
    // const usdt = m.contractAt("USDT", '0xaDBCA24D02CF58133B118D032c0f29e1FC3AC46C');
    // m.call(usdt, "approve", ['0x12b2F2bBEE03c292ec6362DCd8a0D9D022Ad454A', Web3.utils.toWei('200', 'ether')]);
    // contract.deploy();

    return { contract };
});
