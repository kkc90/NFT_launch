const { ethers } = require("hardhat");
const hre = require("hardhat");
const lineReader = require('line-reader');

// const fs = require('fs');
// const fileName = "exp1.txt";

const contract_name = "BatchAuction";
// const contract_address = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
var contract_address;
var eth_address_accounts = [];
var eth_amounts = [];

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function readFiles() {
    try {
        lineReader.eachLine('address_batch.txt', (line) => {
            contract_address = line.split(" ")[0].toString();
            // console.log(contract_address);
        })
    } catch (err) {
        console.log(err)
    }
    // console.log("Contract address: ", contract_address)

    try {
        let line_cnt = 0;
        lineReader.eachLine('users.txt', (line) => {
            array = line.split("\t");
            // console.log("index 0: ", array[0]);
            // console.log("index 1: ", array[1]);
            eth_address_accounts[line_cnt] = array[0];
            eth_amounts[line_cnt] = array[1];
            // console.log(eth_address_accounts[line_cnt]);
            // console.log(eth_amounts[line_cnt]);
            line_cnt++;
        })
    } catch (err) {
        console.log(err)
    }
}


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

    /***
     * Read files to get (contrac address and user accounts)
     */
     readFiles();
     await delay(10000);

    const contract = await ethers.getContractAt(contract_name, contract_address);


    console.log("Index\tAddress\tAmount\tMinted");
    for (let i = 0; i < eth_address_accounts.length; i++) {
        user = eth_address_accounts[i];
        amount = eth_amounts[i];
        wins = (await contract.getUserBidIds(user)).length;

        console.log("%d\t%s\t%s\t%d", i+1, user, amount, wins);
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