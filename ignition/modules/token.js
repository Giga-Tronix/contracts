const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

// const JAN_1ST_2030 = 1893456000;
// const ONE_GWEI = 1_000_000_000n;

module.exports = buildModule("GigaTronixToken", (m) => {
    // const oracle = m.getParameter("_oracle", '0x514910771AF9Ca656af840dff83E8264EcF986CA');
    // const usdt = m.getParameter("_usdt", '0xaDBCA24D02CF58133B118D032c0f29e1FC3AC46C');

    const contract = m.contract("GigaTronix", []);
    // contract.deploy();

    return { contract };
});
