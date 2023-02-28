const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

const contract_name = "BatchAuction";
const userFile = "users.txt";
const caFile = "address_batch.txt";

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
function randn_bm(min, max, skew) {
    let u = 0, v = 0;
    while (u === 0) u = Math.random() //Converting [0,1) to (0,1)
    while (v === 0) v = Math.random()
    let num = Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v)

    num = num / 10.0 + 0.5 // Translate to 0 -> 1
    if (num > 1 || num < 0)
        num = randn_bm(min, max, skew) // resample between 0 and 1 if out of range

    else {
        num = Math.pow(num, skew) // Skew
        num *= max - min // Stretch to fill range
        num += min // offset to min
    }
    return num
}

async function main() {
    // const provider = await ethers.providers.Provider;
    // console.log("Ethereum provider:", provider.);
    // let provider = new ethers.providers.Web3Provider(network.provider);
    let provider;
    if (network.config.url !== undefined) {
        provider = new ethers.providers.JsonRpcProvider(
            network.config.url
        );
    } else {
        // if network.config.url is undefined, then this is the hardhat network
        provider = hre.ethers.provider;
        // provider = new ethers.providers.Web3Provider(network.provider);
    }

    // /***
    //  * Deploy a smart contract for NFT
    //  */
    // let estimatedGas = await provider.getFeeData();
    // console.log("Estimated gasPrice: ", estimatedGas.gasPrice);
    // const DUTCH = await hre.ethers.getContractFactory(contract_name);
    // let dutch = await DUTCH.deploy({ gasPrice: estimatedGas.gasPrice.mul(3) });

    // await dutch.deployed();
    // console.log(
    //     `DutchAuction deployed to ${dutch.address}`
    // );

    // fs.writeFile(caFile, dutch.address, function (err) {
    //     if (err) throw err;
    // });



    /*** 
     * Set up an account of deploying smart contract and distributing ETH to others
     */
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    /*** 
     * Create other accounts who want to get NFTs
     */
    let eth_accounts = [];
    let eth_address_accounts = [];
    let eth_amounts = [];
    let s_dist_cnt = 0;
    let f_dist_cnt = 0;

    for (let i = 0; i < 20000; i++) {
        let wallet = await ethers.Wallet.createRandom();
        // let walletWithProvider = wallet.connect(provider);
        // eth_address_accounts.push(await wallet.getAddress()) //Push
        eth_address_accounts[i] = await wallet.getAddress();

        // // console.log(eth_address_accouts[i]);
        // await provider.send("hardhat_impersonateAccount", [eth_address_accounts[i]]);
        // const account = provider.getSigner(eth_address_accounts[i]);
        // // eth_accounts.push(account); //Push
        // eth_accounts[i] = account;

        // eth_amounts.push(randn_bm(1, 12, 3).toString()) //Push
        eth_amounts[i] = randn_bm(1, 12, 3).toString();

        // // Send ETH to accounts (Distribute)
        // estimatedGas = await provider.getFeeData();
        // let egasPrice = estimatedGas.gasPrice;
        // while (true) {
        //     try {
        //         sendTx = await deployer.sendTransaction({
        //             to: eth_address_accounts[i],
        //             value: ethers.utils.parseEther(eth_amounts[i]),
        //             gasPrice: egasPrice
        //         });
        //         break;
        //     } catch (error) {
        //         console.log(error);
        //         estimatedGas = await provider.getFeeData();
        //         egasPrice = egasPrice.mul(2);
        //         // console.log("Estimated gasPrice: ", estimatedGas.gasPrice);
        //     }
        // }

        // // ==> Change

        balance = ethers.utils.parseEther(eth_amounts[i]);
        correctedHEX = balance.toHexString().replace("0x0", "0x");
        await provider.send("hardhat_setBalance", [
            eth_address_accounts[i],
            correctedHEX,
        ]);

        data = eth_address_accounts[i] + "\t" + eth_amounts[i] + "\n";
        // console.log(data);

        // fs.appendFileSync(userFile, data, function (err) {
        fs.appendFile(userFile, data, function (err) {
            if (err) throw err;
        });
    }

    await delay(1000);


    // for (let i = 0; i < 100; i++) {
    //     console.log("Account %d balance: %s", i, (await provider.getBalance(eth_address_accouts[i])));
    // }

    // const [deployer] = await ethers.getSigners();
    console.log("Ethereum Accounts:", eth_address_accounts);
    console.log("Accounts ETH amounts:", eth_amounts);

    // /***
    //  * Start NFT Launch
    //  */
    // startTx = await dutch.startAuction();
    // await startTx.wait();
    // isActive = await dutch.isAuctionActive();
    // if (isActive != true) {
    //     console.log("Activation failed");
    //     process.exit(1);
    // }


    console.log("##### Setup End #####");

    // console.log(await provider.getBlockNumber())
    // let estimatedGas = await provider.getFeeData();
    // console.log("Estimated Gas:", estimatedGas);
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
