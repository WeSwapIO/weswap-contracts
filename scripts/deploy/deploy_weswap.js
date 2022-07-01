const hre = require("hardhat");

// deploy Exchange

async function main() {

    console.log('running deploy exchange...');

    const exchange = await hre.ethers.getContractFactory("WeSwapExchange");
    const Exchange = await exchange.deploy();
    await Exchange.deployed();
    console.log('Exchange contract deployed to:', Exchange.address);

    console.log('running deploy caller...');

    const caller = await hre.ethers.getContractFactory("WeSwapCaller");
    const Caller = await caller.deploy();
    await Caller.deployed();
    console.log("Caller contract deployed to: ", Caller.address);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
