const { ethers } = require("hardhat");
const hre = require("hardhat");
const lineReader = require('line-reader');

// const fs = require('fs');
// const fileName = "exp1.txt";

const contract_name = "DutchAuction";
// const contract_address = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
var contract_address;

async function main() {
    let provider;
    if (network.config.url !== undefined) {
        provider = new ethers.providers.JsonRpcProvider(
            network.config.url
        );
    } else {
        // if network.config.url is undefined, then this is the hardhat network
        provider = hre.ethers.provider;
    }

    lineReader.eachLine('address.txt', (line) => {
        contract_address = line.split(" ")[0].toString();
        // console.log(contract_address);
    })

    console.log("Blocknumber\tGasUsed\tGasLimit\tBaseFeePerGas\tTxCount");
    let latestBlock = await ethers.provider.getBlockNumber();
    for (let i = 0; i < latestBlock; i++) {
        gasUsed = (await ethers.provider.getBlock(i)).gasUsed;
        gasLimit = (await ethers.provider.getBlock(i)).gasLimit;
        baseGas = (await ethers.provider.getBlock(i)).baseFeePerGas;
        txCount = (await ethers.provider.getBlock(i)).transactions.length;
        console.log("%d\t%d\t%d\t%d\t%d", i, gasUsed, gasLimit, baseGas, txCount);
    }

    // let contract_dutch = await ethers.getContractAt(contract_name, contract.address);
    // console.log("Contract: ", contract_dutch);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
