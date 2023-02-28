// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LaunchNFTa is ERC721A, Ownable {
    // Variables and constants
    uint256 public constant TOTAL_SUPPLY = 1000;
    uint256 public constant MAX_PER_ADDR = 2;
    uint256 public constant MAX_PER_TX = 2;
    uint256 public constant PRICE_PER_TICKET = 1 ether;

    string private baseURI;
    address public operator;

    bool public isParticipateActive = false;
    uint256 public launchStartTime;
    uint256 public launchStopTime;
    uint256 public durationOfLaunch = 30 minutes;

    // bool private isKycCheck = false;
    // bytes32 public kycMerkleRoot;

    uint256 public maxPerTx;
    uint256 public maxPerAddr;
    mapping(address => uint256) public participatedPerAddress;

    uint256 public countOfTickets = 0;
    // address[] public participantList; // should be 'private'
    uint256 public startIndex = 0;

    // uint256 public randomSeed;

    address[] public listOfParticipants;
    address[] public tempList;

    uint256 private seed;
    address[] public winners;
    uint256 public numOfwinners = TOTAL_SUPPLY;
    mapping(address => uint) public countOfwins;

    // modifiers
    modifier onlyOperator() {
        require(operator == msg.sender, "Only operator can call this method");
        _;
    }

    // events
    event LaunchStart(uint256 indexed _Duration, uint256 indexed _startTime);
    event LaunchStop(uint256 indexed _timeElapsed, uint256 indexed _endTime);
    event ParticipateIn(address indexed sender, uint256 indexed num);

    constructor() payable ERC721A("LaunchNFT", "NFT") {
        setOperator(msg.sender);
        maxPerTx = MAX_PER_TX;
        maxPerAddr = MAX_PER_ADDR;
    }

    receive() external payable {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }

    function setOperator(address _operator) private onlyOwner {
        operator = _operator;
    }

    function setDuration(uint256 _duration) external onlyOperator {
        durationOfLaunch = _duration;
    }

    function getElapsedSaleTime() private view returns (uint256) {
        return launchStartTime > 0 ? block.timestamp - launchStartTime : 0;
    }

    // function setKycCheckRequired(bool _isKycCheck) external onlyOperator {
    //     isKycCheck = _isKycCheck;
    // }

    function startLaunch() external onlyOperator {
        require(!isParticipateActive, "Launch already started");
        isParticipateActive = true;
        launchStartTime = block.timestamp;
        emit LaunchStart(durationOfLaunch, launchStartTime);
    }

    function stopLaunch() external onlyOperator {
        require(isParticipateActive, "Launch is not yet started");
        isParticipateActive = false;
        // launchStopTime = block.timestamp;
        if (launchStartTime + durationOfLaunch < getElapsedSaleTime()) {
            launchStopTime = launchStartTime + durationOfLaunch;
        } else {
            launchStopTime = block.timestamp;
        }
        // tempList = listOfParticipants;
        emit LaunchStop(getElapsedSaleTime(), launchStopTime);
    }

    function participateInLaunch(uint256 num) external payable {
        require(isParticipateActive, "Lauch is not yet started");
        require(
            launchStartTime + durationOfLaunch > getElapsedSaleTime(),
            "Launch was closed"
        );
        require(num > 0, "Set at least one");
        require(
            num <= maxPerTx,
            "Tickets in a transaction should not exceed MAX_PER_TX"
        );
        require(
            num + participatedPerAddress[msg.sender] <= maxPerAddr,
            "An address cannot buy NFT raffle tickets more than MAX_PER_ADDR"
        );

        countOfTickets += num;
        participatedPerAddress[msg.sender] += num;

        for (uint256 i; i < num; ++i) {
            listOfParticipants.push(msg.sender);
            tempList.push(msg.sender);
        }
        emit ParticipateIn(msg.sender, num);
    }

    function getAccount(uint index) public view returns (address) {
        return listOfParticipants[index];
    }

    function getParticipants() public view returns (address[] memory) {
        return listOfParticipants;
    }

    function getWinners() public view returns (address[] memory) {
        return winners;
    }

    function getRandomSeed() public view returns (uint256) {
        return seed;
    }

    function setRandomSeed() external onlyOperator {
        seed =
            uint256(keccak256(abi.encodePacked(block.timestamp))) %
            listOfParticipants.length;
    }

    function recalcuateRandomSeed(uint256 selected, uint256 cnt)
        internal
        view
        onlyOperator
        returns (uint256)
    {
        uint result = uint256(keccak256(abi.encodePacked(selected + 1, cnt))) %
            tempList.length;
        // console.log("selected: %s, result: %s", selected, result);
        return result;
    }

    function selectWinners() external onlyOperator {
        uint random = getRandomSeed();
        uint cnt = 0;

        while (winners.length != numOfwinners) {
            if (tempList[random] != address(0)) {
                winners.push(tempList[random]);
                countOfwins[tempList[random]]++;
                tempList[random] = address(0);
            }
            // console.log("Previous Random: %s", random);
            random = recalcuateRandomSeed(random, cnt);
            cnt = ++cnt;
            // console.log("Processed Random: %s", random);
        }
    }

    function removeByIndex(uint index) internal onlyOperator {
        if (index >= tempList.length) return;

        for (uint i = index; i < tempList.length - 1; i++) {
            tempList[i] = tempList[i + 1];
        }
        tempList.pop();
    }

    function selectWinnersV2(uint256 range) external onlyOperator {
        uint random = getRandomSeed();
        uint cnt = 0;

        if (startIndex + range > numOfwinners) {
            range = numOfwinners;
        }

        for (uint i = startIndex; i < range; i++) {
            winners.push(tempList[random]);
            countOfwins[tempList[random]]++;
            removeByIndex(random);
            random = recalcuateRandomSeed(random, cnt);
            cnt = ++cnt;
            range = 0;
        }
        seed = random;
        startIndex = startIndex + range;
    }

    // function clearWinners() internal onlyOperator {
    //     delete winners;
    // }

    // function clearTemp() internal onlyOperator {
    //     tempList = listOfParticipants;
    // }

    // function initAll() external onlyOperator {
    //     for (uint i = 0; i < winners.length; i++) {
    //         countOfwins[winners[i]] = 0;
    //     }
    //     clearWinners();
    //     clearTemp();
    // }

    function settlement() external onlyOperator {
        for (uint i = 0; i < listOfParticipants.length; i++) {
            if (countOfwins[listOfParticipants[i]] != 0) {
                _mint(
                    listOfParticipants[i],
                    countOfwins[listOfParticipants[i]]
                );
            } else {
                // address payable refundUser = payable(listOfParticipants[i]);
                // (bool success, ) = refundUser.call{
                //     value: PRICE_PER_TICKET
                // }("");
                (bool success, ) = listOfParticipants[i].call{
                    value: PRICE_PER_TICKET
                }("");
                require(success, "Failed to transfer ETH");
            }
        }
    }
}
