//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol"; // Azuki: ERC721A
import "@openzeppelin/contracts/access/Ownable.sol"; // OZ: Ownership
import "./libraries/MinPriorityQueue.sol";

import "hardhat/console.sol";

///@notice an implementation of "smart batched auctions" for ERC721. Users are able to enter
///bids with a specified quantity and price during a bidding phase. After the bidding phase is over,
///a clearing price is computed by matching the highest-priced orders with available supply. The
///auction clears at a uniform price, i.e. the lowest price that clears all supply.
contract BatchAuction is ERC721A, Ownable {
    using MinPriorityQueue for MinPriorityQueue.Queue;

    /// @notice Minimum bid price
    uint256 public MIN_BID_PRICE;
    /// @notice Available NFT supply
    uint256 public AVAILABLE_SUPPLY;

    /// @notice Start time for auction
    uint256 public AUCTION_START_TIME;
    /// @notice End time for auction
    uint256 public AUCTION_END_TIME;

    /// ============ Mutable storage ============
    /// @notice Number of NFTs minted
    uint256 public nftCount = 0;
    /// @notice Cost to mint each NFT (in wei)
    uint256 public mintCost;
    /// @notice number of bids committed
    uint256 public numBids;
    /// @notice duration of auction
    uint256 public duration = 20 minutes;
    /// @notice Auction status
    bool public isAuctionActive = false;
    /// @notice Owner has claimed proceeds
    bool public proceedsClaimed = false;

    /// @notice priority queue holding currently winning bids
    MinPriorityQueue.Queue public bidPriorityQueue;

    /// @notice total amount paid for by user
    mapping(address => uint256) public balanceContributed;

    /// @notice event emitted when a new bid is entered
    event BidEntered(address indexed user, uint256 quantity, uint256 price);

    /// @notice event emitted when claim to mint quantity and get refund
    event Claimed(address indexed user, uint256 quantity);

    /// @notice Emitted after owner claims proceeds
    /// @param owner Address of owner
    /// @param amount Amount of proceeds claimed by owner
    event ProceedsClaimed(address indexed owner, uint256 amount);

    constructor() payable ERC721A("BatchAuction", "NFT") {
        //priority queue requires initialization prior to use
        bidPriorityQueue.initialize();
        AVAILABLE_SUPPLY = 1000;
        MIN_BID_PRICE = 1 ether;
    }

    receive() external payable {}

    ///@notice Start auction and set the end time
    function startAuction() public onlyOwner {
        require(!isAuctionActive, "Auction already started");
        isAuctionActive = true;
        AUCTION_START_TIME = block.timestamp;
        AUCTION_END_TIME = AUCTION_START_TIME + duration;
    }

    ///@notice Stop auction
    function stopAuction() public onlyOwner {
        require(isAuctionActive, "Auction not active");
        require(
            numBids == AVAILABLE_SUPPLY,
            "The space for bids still remains"
        );
        isAuctionActive = false;
        AUCTION_END_TIME = block.timestamp;
    }

    ///@notice enter a bid for a specified quantity and price.
    function enterBid(uint256 quantity, uint256 price) external payable {
        require(block.timestamp >= AUCTION_START_TIME, "Auction not active");
        require(block.timestamp <= AUCTION_END_TIME, "Auction ended");
        require(price >= MIN_BID_PRICE, "Insufficient price for bid");
        require(msg.value == quantity * price, "Incorrect payment");

        //keep track of total contribution by user
        balanceContributed[msg.sender] += msg.value;

        //first, accept all bids while there is still available supply
        uint256 remainingSupply = AVAILABLE_SUPPLY - numBids;
        //min between remaining supply and quantity
        uint256 fillAtAnyPriceQuantity = remainingSupply < quantity
            ? remainingSupply
            : quantity;

        if (fillAtAnyPriceQuantity > 0) {
            bidPriorityQueue.insert(msg.sender, price, fillAtAnyPriceQuantity);
            numBids += fillAtAnyPriceQuantity;
        }

        //if any quantity is still unfilled, we need to see if the price beats the lowest bids
        uint256 unfilledQuantity = quantity - fillAtAnyPriceQuantity;
        //process as many bids as possible given current prices
        unfilledQuantity = processBidsInQueue(unfilledQuantity, price);
        uint256 filledQuantity = quantity - unfilledQuantity;
        if (filledQuantity > 0) {
            //update current mint cost
            mintCost = bidPriorityQueue.getMin().price;
            emit BidEntered(msg.sender, filledQuantity, price);
        }
    }

    ///@notice mints NFTs for winning bids, and refunds all remaining contributions
    function claim() public {
        require(block.timestamp > AUCTION_END_TIME, "Auction has not ended");
        //clearing price is the price of the min bid at the time the bidding period is over
        uint256 clearingPrice = bidPriorityQueue.getMin().price;
        uint256 balance = balanceContributed[msg.sender];
        uint256[] storage winningBidIds = bidPriorityQueue.ownerToBidIds[
            msg.sender
        ];
        //iterate through winning bids, minting correct quantity for user
        uint256 curNFTCount = nftCount;
        for (uint256 i = 0; i < winningBidIds.length; i++) {
            uint256 curBidId = winningBidIds[i];
            Bid storage curBid = bidPriorityQueue.bidIdToBidMap[curBidId];
            //cache quantity in memory for price calc and minting
            uint256 qty = curBid.quantity;
            //charge user quantity times clearing price
            //update balance and quantity before minting to prevent reentrant claims
            balance -= qty * clearingPrice;
            curBid.quantity = 0;
            for (uint256 j = 0; j < qty; j++) {
                _mint(msg.sender, ++nftCount);
            }
        }
        //refund any contributions not spent on mint
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Unsuccessful in refund");
        emit Claimed(msg.sender, nftCount - curNFTCount);
    }

    ///@notice try to accept bid for specifc quantity and price. Return unfilled quantity
    function processBidsInQueue(
        uint256 quantity,
        uint256 price
    ) private returns (uint256) {
        //loop while we are still trying to fill bids
        while (quantity > 0) {
            //get current lowest bid
            Bid storage lowestBid = bidPriorityQueue.getMin();
            //if we can't beat lowest bid, break
            if (lowestBid.price >= price) {
                break;
            }
            uint256 lowestBidQuantity = lowestBid.quantity;

            //if lowest bid has higher quantity that what we need to fill,
            //reduce that bid's quantity by respective amount
            if (lowestBidQuantity > quantity) {
                //reduce quantity of lowest bid. This can be safely done in place
                lowestBid.quantity -= quantity;
                //put new bid in queue
                bidPriorityQueue.insert(msg.sender, price, quantity);
                quantity = 0;
            }
            //else we remove lowest bid completely
            else {
                //eliminate lowest bid
                bidPriorityQueue.delMin();
                //fill appropriate quantity of new bid
                bidPriorityQueue.insert(msg.sender, price, lowestBidQuantity);
                //update quantity that we still need to fill
                quantity -= lowestBidQuantity;
            }
        }
        return quantity;
    }

    function getUserBidIds(
        address addr
    ) public view returns (uint256[] memory) {
        return bidPriorityQueue.ownerToBidIds[addr];
    }

    function getBidById(uint256 id) public view returns (Bid memory) {
        return bidPriorityQueue.bidIdToBidMap[id];
    }

    /// @notice Allows contract owner to withdraw proceeds of winning tickets
    function withdrawProceeds() external onlyOwner {
        // Ensure raffle has ended
        require(block.timestamp > AUCTION_END_TIME, "Auction has not ended");
        // Ensure proceeds have not already been claimed
        require(!proceedsClaimed, "Proceeds already claimed");

        // Toggle proceeds being claimed
        proceedsClaimed = true;

        // proceeds are equal to final mint price times number of bids
        uint256 proceeds = mintCost * numBids;

        // Pay owner proceeds
        (bool sent, ) = payable(msg.sender).call{value: proceeds}("");
        require(sent, "Unsuccessful in payout");

        // Emit successful proceeds claim
        emit ProceedsClaimed(msg.sender, proceeds);
    }
}
