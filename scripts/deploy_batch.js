const { ethers } = require("hardhat");
const fs = require("fs");
const caFile = "address_batch.txt";
const contract_name = "BatchAuction";

async function main() {
    if (network.config.url !== undefined) {
        provider = new ethers.providers.JsonRpcProvider(
            network.config.url
        );
    } else {
        // if network.config.url is undefined, then this is the hardhat network
        provider = hre.ethers.provider;
        // provider = new ethers.providers.Web3Provider(network.provider);
    }

    let estimatedGas = await provider.getFeeData();
    console.log("Estimated gasPrice: ", estimatedGas.gasPrice);

    const Lib = await ethers.getContractFactory("MinPriorityQueue");
    const lib = await Lib.deploy();
    await lib.deployed();

    const BATCH = await hre.ethers.getContractFactory(contract_name, {
        libraries: {
            MinPriorityQueue: lib.address,
        },
    });
    let batch = await BATCH.deploy({ gasPrice: estimatedGas.gasPrice.mul(3) });

    await batch.deployed();
    console.log(
        `BatchAuction deployed to ${batch.address}`
    );

    fs.writeFile(caFile, batch.address, function (err) {
        if (err) throw err;
    });



    /*** 
     * Set up an account of deploying smart contract and distributing ETH to others
     */
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    /***
     * Start NFT Launch
     */
    startTx = await batch.startAuction();
    await startTx.wait();
    isActive = await batch.isAuctionActive();
    if (isActive != true) {
        console.log("Activation failed");
        process.exit(1);
    }

    console.log("##### Setup End #####");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
