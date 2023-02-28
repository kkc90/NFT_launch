// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DutchAuction is ERC721A, Ownable {
    // Dutch Auction's parameters: startTime, startPrice, changePeriod, decreasingFactor, restingPrice
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startPrice;
    uint256 public restingPrice;
    uint256 public changePeriod;
    uint256 public decreasingFactor;

    bool public isAuctionActive = false;
    uint256 public maxPerTx;
    uint256 public maxPerAddr;
    mapping(address => uint256) public mintedPerAddress;
    uint256 public mintCount;

    uint256 public constant TOTAL_SUPPLY = 1000;
    uint256 public constant MAX_PER_ADDR = 2;
    uint256 public constant MAX_PER_TX = 2;

    constructor() payable ERC721A("DutchAuction", "NFT") {
        startPrice = 10 ether;
        changePeriod = 2 minutes;
        decreasingFactor = 1 ether;
        restingPrice = 1 ether;
        maxPerTx = MAX_PER_TX;
        maxPerAddr = MAX_PER_ADDR;
    }

    receive() external payable {}

    function startAuction() public onlyOwner {
        require(!isAuctionActive, "Auction already started");
        isAuctionActive = true;
        startTime = block.timestamp;
    }

    function stopAuction() public onlyOwner {
        require(isAuctionActive, "Auction was not yet started");
        require(mintCount == TOTAL_SUPPLY, "NFTs stil remain");
        isAuctionActive = false;
        endTime = block.timestamp;
    }

    // function calculatePrice() public view returns (uint256) {
    //     uint256 tick = uint256((block.timestamp - startTime) / changePeriod);

    //     uint256 calculatedPrice = startPrice - tick * decreasingFactor;
    //     if (calculatedPrice < restingPrice) {
    //         return restingPrice;
    //     } else {
    //         return calculatedPrice;
    //     }
    // }

    function calculatePrice() public view returns (uint256) {
        uint256 tick = uint256((block.timestamp - startTime) / changePeriod);
        // console.log(
        //     "Timestamp: %d, StartTime: %d, Tick: %d",
        //     block.timestamp,
        //     startTime,
        //     tick
        // );

        int256 calculatedPrice = int256(startPrice) -
            int256(tick * decreasingFactor);

        // console.log("Calculated price: ", calculatedPrice);

        if (calculatedPrice < int256(restingPrice)) {
            return restingPrice;
        } else {
            return uint256(calculatedPrice);
        }
    }

    function mintNFT(uint256 num) public payable {
        require(isAuctionActive, "Auction was not yet started");
        require(num > 0, "Set at least one");
        require(
            num <= maxPerTx,
            "Minting NFTs in a transaction should not exceed MAX_PER_TX"
        );
        require(
            num + mintedPerAddress[msg.sender] <= maxPerAddr,
            "An address cannot mint NFTs more than MAX_PER_ADDR"
        );

        require(num + mintCount <= TOTAL_SUPPLY, "Total supply exceeds");

        uint256 requiredCost = num * calculatePrice();
        require(msg.value >= requiredCost, "Value is not enough");

        mintedPerAddress[msg.sender] += num;
        mintCount += num;
        _mint(msg.sender, num);
        uint256 change = msg.value - requiredCost;
        if (change != 0) {
            (bool success, ) = msg.sender.call{value: change}("");
            require(success, "Failed to refund the change");
        }
    }

    function withdraw() public onlyOwner {
        require(endTime != 0, "Auction was not finished");
        uint256 balance = address(this).balance;

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw ETH");
    }
}
