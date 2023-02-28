const { ethers } = require("hardhat");
const fs = require("fs");
const lineReader = require('line-reader');

const contract_name = "LaunchNFTa";
let contract_address;

// const increaseGasLimit = (estimatedGasLimit) => {
//     return estimatedGasLimit.mul(130).div(100) // increase by 30%
// }

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function readFile() {
    try {
        lineReader.eachLine('address_raffle.txt', (line) => {
            contract_address = line.split(" ")[0].toString();
            // console.log(contract_address);
        })
    } catch (err) {
        console.log(err)
    }
    // console.log("Contract address: ", contract_address)
}


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

    /***
     * Read files to get (contrac address and user accounts)
     */
    readFile();
    await delay(3000);


    let estimatedGas = await provider.getFeeData();
    console.log("Estimated gasPrice: ", estimatedGas.gasPrice);

    /*** 
     * Set up an account of deploying smart contract and distributing ETH to others
     */
    const [deployer] = await ethers.getSigners();
    const RAFFLE = await ethers.getContractAt(contract_name, contract_address);
    const raffle = RAFFLE.connect(deployer);


    /***
     * Start NFT Launch
     */
    stopTx = await raffle.stopLaunch();
    await stopTx.wait();
    isActive = await raffle.isParticipateActive();
    if (isActive != false) {
        console.log("Deactivation failed");
        process.exit(1);
    }

    /***
     * Set seed
     */
    setRandomTx = await raffle.setRandomSeed();
    await setRandomTx.wait();

    random_seed = await raffle.getRandomSeed();
    console.log("Random Seed: ", random_seed);



    console.log("##### Setup End #####");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
