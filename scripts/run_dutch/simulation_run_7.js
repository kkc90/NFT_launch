const { ethers } = require("hardhat");
const hre = require("hardhat");
const lineReader = require('line-reader');

// const helpers = require("@nomicfoundation/hardhat-network-helpers");

let file_idx = 7;
let provider;

// let mint_price = "1.0";
let contract_name = "DutchAuction";
let contract_address;
let ts;

let eth_accounts = [];
let eth_address_accounts = [];
let eth_amounts = [];

let g_gasLimit;

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


async function virtualUser(eth_account) {
    let address = await eth_account.getAddress();
    // console.log("Account:", address);

    // console.log(await ethers.Signer.isSigner(eth_account));
    const signer = provider.getSigner(address);
    // console.log(signer)

    // const bytecode = await provider.getCode(contract.address);
    // console.log("Bytecode:", bytecode);
    // const contract_user = new ethers.ContractFactory(abi, bytecode, eth_account);
    // console.log(contract_user);

    let contract_user = await ethers.getContractAt(contract_name, contract_address);
    let mintPrice = await contract_user.calculatePrice();
    // console.log("NFT minting price:", mintPrice);

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
    // console.log("Balance: ", balance);

    mc = await contractWithSigner.mintCount();
    // console.log("Mint count: ", mc);

    // await deley(1);
    console.log("Account: " + address + ", NFT minting price: " + mintPrice + ", lastBaseFeePerGas: " + baseFeePerGas + ", Balance: " + balance + ", Mint count: " + mc);

    if (mc.lt(ts)) {
        let tx;
        let cost;
        if (balance.gt(mintPrice)) {
            try {
                tx = await contractWithSigner.estimateGas.mintNFT(1, { value: mintPrice });
                // console.log("Estimated gas for mint tx: ", tx);
                txfee = ethers.utils.formatUnits(tx * baseFeePerGas + tx * priorityFeePerGas, "ether");
                // console.log("Tx fee (ETH): ", txfee);
                cost = mintPrice.add(ethers.utils.parseEther(txfee));
                // console.log("Tx fee + Mint price (ETH): ", cost);
                console.log("Estimated gas for mint tx: " + tx + "Tx fee (ETH): " + txfee + "Tx fee + Mint price (ETH): " + cost);

            } catch (error) {
                console.log("(Estimating tx gas) Error: ", error);
                tx = ethers.BigNumber.from("1000000");
                // console.log("Estimated gas for mint tx: ", tx);
                txfee = ethers.utils.formatUnits(tx * baseFeePerGas + tx * priorityFeePerGas, "ether");
                // console.log("Tx fee (ETH): ", txfee);
                cost = mintPrice.add(ethers.utils.parseEther(txfee));
                // console.log("Tx fee + Mint price (ETH): ", cost);
                console.log("Estimated gas for mint tx: " + tx + "Tx fee (ETH): " + txfee + "Tx fee + Mint price (ETH): " + cost);

            }

            // ??? while is correct???
            // nonce_user = await eth_account.getTransactionCount();
            while (true) {
                if (balance.gte(cost)) {
                    // Priority Fee Setup
                    egasPrice = baseFeePerGas.add(priorityFeePerGas);
                    remaining = balance.sub(cost);
                    up = remaining.div(mintPrice);
                    egasPrice = (egasPrice.mul(2)).add(egasPrice.mul(up));

                    try {
                        tx_sent = await contractWithSigner.mintNFT(1, { gasLimit: tx, value: mintPrice, gasPrice: egasPrice });
                        console.log("Tx: ", tx_sent);
                        break;
                    } catch (error) {
                        console.log("(Sending tx) Error: ", error);
                        egasPrice = egasPrice.mul(2);
                        // tx_sent = await contractWithSigner.mintNFT(1, { gasLimit: tx, value: mintPrice, gasPrice: egasPrice });
                        // console.log("Receipt: ", tx_sent);
                    }
                } else {
                    break;
                }
            }
        }
    }
}

function readFiles() {
    try {
        lineReader.eachLine('address.txt', (line) => {
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
            if (line_cnt >= 2000 * (file_idx - 1) && line_cnt < 2000 * (file_idx)) {
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


    for (let i = 0; i < 2000; i++) {
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
    const DUTCH = await ethers.getContractAt(contract_name, contract_address);
    const dutch = DUTCH.connect(deployer);

    // stime = await dutch.startTime();
    // console.log("Start time: ", stime);
    // console.log("(main) DutchAuction's Mint price: ", await dutch.calculatePrice());


    // console.log(await ethers.Signer.isSigner(eth_accounts[0]));

    // await virtualUser(provider, dutch, eth_accounts[0]);
    // await virtualUser(provider, dutch, eth_accounts[1]);

    ts = await dutch.TOTAL_SUPPLY();
    console.log("Total supply: ", ts);
    // let loop_cnt = 0;
    while (true) {
        shuffle(eth_accounts);
        mc = await dutch.mintCount();
        let workQueue = [];
        if (mc == ts) {
            break;
        } else {
            // console.log("############## Round %d ##############", loop_cnt++);
            for (let i = 0; i < eth_accounts.length; i++) {
                // await delay(5);
                await virtualUser(eth_accounts[i]);


                // console.log(eth_accounts[i]);
                // let estimatedGas = await provider.getFeeData();
                // console.log("lastBaseFeePerGas:", estimatedGas.lastBaseFeePerGas);
            }
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
