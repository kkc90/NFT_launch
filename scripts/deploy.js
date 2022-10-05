const hre = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // const lockedAmount = hre.ethers.utils.parseEther("1");

    const VRF = await hre.ethers.getContractFactory("VRFTest");
    const vrf = await VRF.deploy();

    await vrf.deployed();

    console.log(
        `VRFTest deployed to ${vrf.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
