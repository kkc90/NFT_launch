# Setup
from web3 import Web3

alchemy_url = "https://eth-goerli.g.alchemy.com/v2/f7jlKtXuyg0fl3jxFaDKIe-7ff9H76iy"
w3 = Web3(Web3.HTTPProvider(alchemy_url))
  
# Print if web3 is successfully connected
print(w3.isConnected())

# Get the latest block number
latest_block = w3.eth.block_number
print(latest_block)

# Get the balance of an account
balance = w3.eth.get_balance('0x03c659c89537372eD4B77218BcFcA17f81e07D07')
print(balance)

# Get the information of a transaction
tx = w3.eth.get_transaction('0x958c0d02adc0be2a97f19ba78fc6089dc43318d184a883aaf6824afb3b6be779')
print(tx)
