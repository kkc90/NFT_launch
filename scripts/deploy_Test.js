const hre = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // const lockedAmount = hre.ethers.utils.parseEther("1");

    const TEST = await hre.ethers.getContractFactory("TestGas");
    const test = await TEST.deploy({ value: "5000000000000000000" });

    await test.deployed();

    console.log(
        `Raffle deployed to ${test.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
