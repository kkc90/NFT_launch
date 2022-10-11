require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

// /** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.17",
// };

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const INFURA_API_KEY = process.env.INFURA_API_KEY;

const ALCHEMY_URL = `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`;
const INFURA_URL = `https://goerli.infura.io/v3/${INFURA_API_KEY}`;


module.exports = {
  defaultNetwork: "localhost",
  solidity: "0.8.9",
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  networks: {
    hardhat: {
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    goerli: {
      url: ALCHEMY_URL,
      accounts: [GOERLI_PRIVATE_KEY]
    },
  },
};