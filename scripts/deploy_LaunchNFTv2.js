const hre = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // const lockedAmount = hre.ethers.utils.parseEther("1");

    const NFT = await hre.ethers.getContractFactory("LaunchNFTv2");
    const nft = await NFT.deploy();

    // console.log(nft);

    await nft.deployed();

    console.log(
        `LaunchNFTv2 deployed to ${nft.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
