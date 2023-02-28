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

    console.log("Blocknumber\tTxCount\tSuccess\tFail");
    let latestBlock = await ethers.provider.getBlockNumber();
    for (let i = 0; i < latestBlock; i++) {
        txCount = (await ethers.provider.getBlock(i)).transactions.length;
        txs = (await ethers.provider.getBlock(i)).transactions;

        let success = 0;
        let fail = 0;
        for (let j = 0; j < txs.length; j++) {
            receipt = await provider.getTransactionReceipt(txs[j]);

            if (receipt.status == 1) {
                success++;
            } else {
                fail++;
            }
        }
        console.log("%d\t%d\t%d\t%d", i, txCount, success, fail);
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
