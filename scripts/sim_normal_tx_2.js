const { ethers } = require("hardhat");
const hre = require("hardhat");
// const { NonceManager } = require("@ethersproject/experimental");

// const fs = require('fs');
// const fileName = "exp1.txt";

const contract_name = "DutchAuction";
const contract_address = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

let nonce_map = {};

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function sendETH(from_account, to_address, value) {
    nonceFrom = nonce_map[from_account.address];
    nonce_map[from_account.address] = nonce_map[from_account.address] + 1;

    console.log("From: ", from_account.address);
    console.log("To: ", to_address);
    console.log("From's Nonce: ", nonceFrom);

    try {
        receipt = await from_account.sendTransaction({
            to: to_address,
            value: ethers.utils.parseEther(value),
            nonce: nonceFrom
        });
        console.log(receipt);
    } catch (error) {
        console.log(error);
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

    const user1 = (await ethers.getSigners())[3];
    const user2 = (await ethers.getSigners())[4];
    const users = [];
    users.push(user1);
    users.push(user2);
    nonce_map[user1.address] = await user1.getTransactionCount();
    nonce_map[user2.address] = await user2.getTransactionCount();

    // for (let i = 0; i < users.length; i++) {
    //     console.log(users[i]);
    // }

    // console.log("User 1: ", user1.address);
    // console.log("User 2: ", user2.address);

    let cnt = 0;
    while(true) {
        from = users[cnt%2];
        to = users[(cnt+1)%2];
        cnt++;
        await sendETH(from, to.address, "0.1")
        await delay(100);
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
