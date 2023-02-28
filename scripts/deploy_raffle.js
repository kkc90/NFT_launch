const { ethers } = require("hardhat");
const fs = require("fs");
const caFile = "address_raffle.txt";
const contract_name = "LaunchNFTa";

// const increaseGasLimit = (estimatedGasLimit) => {
//     return estimatedGasLimit.mul(130).div(100) // increase by 30%
// }

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

    // Increase "EstimatedGas"
    // const estimatedGas = await contract.estimateGas.method(args)
    // const tx = await contract.method(args, { gasLimit: increaseGasLimit(estimatedGas) })

    // const Lib = await ethers.getContractFactory("MinPriorityQueue");
    // const lib = await Lib.deploy();
    // await lib.deployed();

    // const BATCH = await hre.ethers.getContractFactory(contract_name, {
    //     libraries: {
    //         MinPriorityQueue: lib.address,
    //     },
    // });
    tx = ethers.BigNumber.from("8000000");
    const RAFFLE = await hre.ethers.getContractFactory(contract_name);
    let raffle = await RAFFLE.deploy({ gasPrice: estimatedGas.gasPrice.mul(3) });

    await raffle.deployed();
    console.log(
        `Raffle-based NFT launch deployed to ${raffle.address}`
    );

    fs.writeFile(caFile, raffle.address, function (err) {
        if (err) throw err;
    });



    /*** 
     * Set up an account of deploying smart contract and distributing ETH to others
     */
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // setSeedTx = await raffle.setRandomSeed();
    // await setSeedTx.wait();
    // console.log("Random seed: ", await raffle.getRandomSeed());

    /***
     * Start NFT Launch
     */
    startTx = await raffle.startLaunch();
    await startTx.wait();
    isActive = await raffle.isParticipateActive();
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
