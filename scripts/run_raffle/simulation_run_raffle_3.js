const { ethers } = require("hardhat");
const hre = require("hardhat");
const lineReader = require('line-reader');

// const helpers = require("@nomicfoundation/hardhat-network-helpers");

let file_idx = 3;
let limit_agent = 2000;
let provider;

// let mint_price = "1.0";
let contract_name = "LaunchNFTa";
let contract_address;

let eth_accounts = [];
let eth_address_accounts = [];
let eth_amounts = [];

let startTime;
let ticket_price;
let duration;
let ts;


function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const random_p = Math.floor(Math.random() * (i + 1));
        const tmp = array[i];
        array[i] = array[random_p];
        array[random_p] = tmp;
    }
}

// async function processArray(array) {
//     // map array to promises
//     const promises = array.map(virtualUser);
//     // wait until all promises are resolved
//     try {
//         await Promise.allSettled(promises);
//     } catch (error) {
//         console.error(error);

//     }
// }


async function virtualUser(eth_account) {
    let address = await eth_account.getAddress();
    // console.log("Account:", address);

    const signer = provider.getSigner(address);
    // console.log(signer)

    let contract_user = await ethers.getContractAt(contract_name, contract_address);

    let contractWithSigner = contract_user.connect(signer);
    // console.log(contractWithSigner);

    // console.log("Block number (latest): ", await provider.getBlockNumber())
    // let startBlk = await provider.getBlockNumber();
    let estimatedGas = await provider.getFeeData();
    let baseFeePerGas = estimatedGas.lastBaseFeePerGas;
    let egasPrice = estimatedGas.gasPrice;
    // console.log("lastBaseFeePerGas:", baseFeePerGas);

    let priorityFeePerGas = baseFeePerGas;

    // balance = await provider.getBalance(address);
    balance = await eth_account.getBalance();
    // balance = eth_amount;
    // console.log("Balance: ", balance);

    let ticket_count = await contractWithSigner.countOfTickets();
    // let mintPrice = ticket_price;

    // let latestBlock = await ethers.provider.getBlockNumber();
    // let blocktimestamp = (await provider.getBlock(latestBlock)).timestamp;
    js_time = Math.floor(Date.now() / 1000);
    // let remainingTime = (startTime + duration) - js_time;

    // await deley(1);
    console.log("Account: " + address + ", Raffle ticket price: " + ticket_price + ", lastBaseFeePerGas: " + baseFeePerGas + ", Balance: " + balance + ", Ticket sold count: " + ticket_count);

    rand = Math.random();
    if (rand > 0.95) {
        tx = ethers.BigNumber.from("5000000");
        // console.log("Estimated gas for mint tx: ", tx);
        // txfee = ethers.utils.formatUnits(tx * baseFeePerGas + tx * priorityFeePerGas, "ether");
        txfee = ethers.utils.formatUnits(tx * egasPrice, "ether");
        // console.log("Tx fee (ETH): ", txfee);
        cost = ticket_price.add(ethers.utils.parseEther(txfee));
        // console.log("Tx fee + Mint price (ETH): ", cost);
        console.log("gasLimit for mint tx: " + tx + ", Tx fee (ETH): " + txfee + ", Tx fee + Bid price (ETH): " + cost);
        // egasPrice = baseFeePerGas.add(priorityFeePerGas);
        if (balance.gt(cost)) {
            try {
                tx_sent = await contractWithSigner.participateInLaunch(1, { gasLimit: tx, value: ticket_price, gasPrice: egasPrice });
                console.log("Tx: ", tx_sent);
            } catch (error) {
                console.log("(Sending tx) Error: ", error);
            }
        }
    }

    // if (balance.gt(ticket_price)) {

    //     tx = ethers.BigNumber.from("5000000");
    //     // console.log("Estimated gas for mint tx: ", tx);
    //     // txfee = ethers.utils.formatUnits(tx * baseFeePerGas + tx * priorityFeePerGas, "ether");
    //     txfee = ethers.utils.formatUnits(tx * egasPrice, "ether");
    //     // console.log("Tx fee (ETH): ", txfee);
    //     cost = ticket_price.add(ethers.utils.parseEther(txfee));
    //     // console.log("Tx fee + Mint price (ETH): ", cost);
    //     console.log("gasLimit for mint tx: " + tx + ", Tx fee (ETH): " + txfee + ", Tx fee + Bid price (ETH): " + cost);
    //     // egasPrice = baseFeePerGas.add(priorityFeePerGas);

    //     try {
    //         tx_sent = await contractWithSigner.participateInLaunch(1, { gasLimit: tx, value: ticket_price, gasPrice: egasPrice });
    //         console.log("Tx: ", tx_sent);
    //     } catch (error) {
    //         console.log("(Sending tx) Error: ", error);
    //     }
    // }
}

function readFiles() {
    try {
        lineReader.eachLine('address_raffle.txt', (line) => {
            contract_address = line.split(" ")[0].toString();
            // console.log(contract_address);
        })
    } catch (err) {
        console.log(err)
    }
    // console.log("Contract address: ", contract_address)

    try {
        let line_cnt = 0;
        let arr_idx = 0;
        lineReader.eachLine('users.txt', (line) => {
            if (line_cnt >= limit_agent * (file_idx - 1) && line_cnt < limit_agent * (file_idx)) {
                array = line.split("\t");
                // console.log("index 0: ", array[0]);
                // console.log("index 1: ", array[1]);
                eth_address_accounts[arr_idx] = array[0];
                eth_amounts[arr_idx] = array[1];
                // console.log(eth_address_accounts[line_cnt]);
                // console.log(eth_amounts[line_cnt]);    
                arr_idx++;
            }
            line_cnt++;
        })
    } catch (err) {
        console.log(err)
    }
    // console.log("Array of Accounts: ", eth_address_accounts)
    // console.log("Array of Balances: ", eth_amounts)
}


async function main() {
    // const provider = await ethers.providers.Provider;
    // console.log("Ethereum provider:", provider.);
    // let provider = new ethers.providers.Web3Provider(network.provider);
    // let provider;
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
    readFiles();
    await delay(3000);
    // console.log("Contract address: ", contract_address)
    // console.log("Array of Accounts: ", eth_address_accounts)
    // console.log("Array of Balances: ", eth_amounts)


    for (let i = 0; i < eth_address_accounts.length; i++) {
        await provider.send("hardhat_impersonateAccount", [eth_address_accounts[i]]);
        let account = provider.getSigner(eth_address_accounts[i]);
        eth_accounts[i] = account;
    }

    // console.log(eth_address_accounts);
    // console.log(eth_address_accounts.length);
    // console.log(eth_amounts);
    // console.log(eth_amounts.length);



    /*** 
     * Set up an account of deploying smart contract and distributing ETH to others
     */
    const [deployer] = await ethers.getSigners();
    const RAFFLE = await ethers.getContractAt(contract_name, contract_address);
    const raffle = RAFFLE.connect(deployer);

    startTime = Number(await raffle.launchStartTime());
    ticket_price = await raffle.PRICE_PER_TICKET();
    duration = Number(await raffle.durationOfLaunch());


    // /***
    //  * Start NFT Launch
    //  */
    // startTx = await batch.startAuction();
    // await startTx.wait();
    // isActive = await batch.isAuctionActive();
    // if (isActive != true) {
    //     console.log("Activation failed");
    //     process.exit(1);
    // }

    // stime = await dutch.startTime();
    // console.log("Start time: ", stime);
    // console.log("(main) DutchAuction's Mint price: ", await dutch.calculatePrice());


    // console.log(await ethers.Signer.isSigner(eth_accounts[0]));

    // await virtualUser(provider, dutch, eth_accounts[0]);
    // await virtualUser(provider, dutch, eth_accounts[1]);

    let loop_cnt = 0;
    // previous = 0;
    while (true) {
        // latestBlock = await ethers.provider.getBlockNumber();
        // blocktimestamp = (await provider.getBlock(latestBlock)).timestamp;
        js_time = Math.floor(Date.now() / 1000);
        remainingTime = (startTime + duration) - js_time;
        // Check Time calculation
        // if (latestBlock > previous) {
        //     console.log("Latest block: " + latestBlock + ", block timestamp: " + blocktimestamp + ", Unix timestamp: " + js_time + ", Remaining time: " + remainingTime, ", Duration: " + duration + ", Start: " + startTime)
        //     previous =  latestBlock;
        // }


        shuffle(eth_accounts);
        // let workQueue = [];
        if (remainingTime + 60 > 0) {
            console.log("############## Round %d ##############", ++loop_cnt);
            for (let i = 0; i < eth_accounts.length; i++) {
                // await delay(5000);
                await virtualUser(eth_accounts[i]);
                // workQueue.push(eth_accounts[i],eth_amounts[i]);


                // console.log(eth_accounts[i]);
                // let estimatedGas = await provider.getFeeData();
                // console.log("lastBaseFeePerGas:", estimatedGas.lastBaseFeePerGas);
            }
            // processArray(workQueue);

        } else {
            break;
        }
    }
    console.log("##### End #####");
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
