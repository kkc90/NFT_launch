// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "erc721a/contracts/ERC721A.sol";
import "hardhat/console.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LaunchNFT is ERC721A, VRFV2WrapperConsumerBase, ConfirmedOwner {
    // For Chainlink VRF
    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Variables and constants
    uint256 public constant TOTAL_SUPPLY = 5;
    uint256 public constant MAX_PER_ADDR = 2;
    uint256 public constant MAX_PER_TX = 2;
    uint256 public constant PRICE_PER_TICKET = 0.001 ether;

    string private baseURI;
    address public operator;

    bool public isParticipateActive = false;
    uint256 public launchStartTime;
    uint256 public launchStopTime;
    uint256 public durationOfLaunch = 5 minutes;

    // bool private isKycCheck = false;
    // bytes32 public kycMerkleRoot;

    uint256 public maxPerTx;
    uint256 public maxPerAddr;
    mapping(address => uint256) public participatedPerAddress;

    uint256 private countOfTickets = 0;
    // address[] public participantList; // should be 'private'

    // uint256 public randomSeed;

    address[] public listOfParticipants = [
        0xD119A4b0ECAb5983E74A8f9AC8e1f32C48Efcfcf,
        0xF9Ef4b1d33ae37DfE5F82E1B91FfD12d62d5551a,
        0x034C9f2d589Aa70B963bBc90929B55fd26890678,
        0xE06644881F40f96a74eFf6224Ece45f1068a5FC1,
        0x2a19Ff2F460DF0b1446e6cDae8aE646390800e1e,
        0xDD24313433D5b670e43e24d63DCb487Ad2D29eC8,
        0xA50eEf1178B2C3ef8C73D0eEBbcD14f3f87E7E6b,
        0x9160A61c08884d418dC0CFF6523FD5362da5410e,
        0x572D94477D3df3A7EE78230dC86a1AF27f41907c,
        0xB6f737e9787D90aF7c06ef3E287f84dbb2934838,
        0xCE6D662d7611E100Cc16C372fD2C5aBE1734CB55,
        0xa6E63083B5E72a06B907403e1850e1380C895816,
        0xcdc6fa0c30d171c3CfdBF283Ad30b618Afbf29a1,
        0xee8229352c7f7501DDE85D253bd9c574a6396953,
        0x221bC9A22cAAA1e27c317244573e7081d3E2628C
    ];

    address[] public tempList = listOfParticipants;
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
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    event LaunchStart(uint256 indexed _Duration, uint256 indexed _startTime);
    event LaunchStop(uint256 indexed _timeElapsed, uint256 indexed _endTime);
    event ParticipateIn(address indexed sender, uint256 indexed num);

    constructor()
        payable
        ERC721A("LaunchNFT", "NFT")
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
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
        launchStopTime = block.timestamp;
        if (launchStartTime + durationOfLaunch < getElapsedSaleTime()) {
            launchStopTime = launchStartTime + durationOfLaunch;
        } else {
            launchStopTime = block.timestamp;
        }
        emit LaunchStop(getElapsedSaleTime(), launchStopTime);
    }

    function participateInLaunch(uint256 num) external payable {
        require(isParticipateActive, "Lauch is not yet started");
        require(
            launchStartTime + durationOfLaunch < getElapsedSaleTime(),
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
        }
        emit ParticipateIn(msg.sender, num);
    }

    function requestRandomSeed()
        external
        onlyOperator
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            fulfilled: false,
            randomWords: new uint256[](0)
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    //  should be 'private'
    function calculateRandomSeed() public view returns (uint256 result) {
        require(s_requests[lastRequestId].fulfilled != false);
        return
            s_requests[lastRequestId].randomWords[0] %
            listOfParticipants.length;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomWords
        )
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    // Allow withdraw of Link tokens from the contract
    function withdrawLink() public onlyOperator {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
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

    function setRandomSeed(uint num) external onlyOperator {
        seed = num;
    }

    function calcuateRandomSeed() external onlyOperator returns (uint256) {
        // should be guranteed to only 1 execution
        seed =
            s_requests[lastRequestId].randomWords[0] %
            listOfParticipants.length;
        return seed;
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

    function selectWinnersV2() external onlyOperator {
        uint random = getRandomSeed();
        uint cnt = 0;

        for (uint i = 0; i < numOfwinners; i++) {
            winners.push(tempList[random]);
            countOfwins[tempList[random]]++;
            removeByIndex(random);
            random = recalcuateRandomSeed(random, cnt);
            cnt = ++cnt;
        }
    }

    function clearWinners() internal onlyOperator {
        delete winners;
    }

    function clearTemp() internal onlyOperator {
        tempList = listOfParticipants;
    }

    function initAll() external onlyOperator {
        for (uint i = 0; i < winners.length; i++) {
            countOfwins[winners[i]] = 0;
        }
        clearWinners();
        clearTemp();
    }

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
