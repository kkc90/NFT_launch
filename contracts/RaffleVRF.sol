// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract RaffleVRF is VRFV2WrapperConsumerBase, ConfirmedOwner {
    address[] public listOfParticipants = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
        0x617F2E2fD72FD9D5503197092aC168c91465E7f2,
        0x17F6AD8Ef982297579C203069C1DbfFE4348c372,
        0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,
        0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,
        0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C,
        0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC,
        0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c,
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,
        0x583031D1113aD414F02576BD6afaBfb302140225,
        0xdD870fA1b7C4700F2BD7f44238821C26f7392148
    ];

    address[] public tempList = listOfParticipants;
    uint256 public seed;
    address[] public winners;
    uint256 public numOfwinners = 5;

    mapping(address => uint) countOfwins;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
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

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
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

    function calcuateRandomSeed() external onlyOwner returns (uint256) {
        // should be guranteed to only 1 execution
        seed =
            s_requests[lastRequestId].randomWords[0] %
            listOfParticipants.length;
        return seed;
    }

    function recalcuateRandomSeed(uint256 selected)
        internal
        view
        onlyOwner
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(selected++))) % tempList.length;
    }

    function selectUsers() public returns (address[] memory) {
        uint random = getRandomSeed();

        do {
            if (tempList[random] != address(0)) {
                winners.push(tempList[random]);
                countOfwins[tempList[random]]++;
                tempList[random] = address(0);
            } else {
                random = recalcuateRandomSeed(random);
            }
        } while (winners.length != numOfwinners);

        return winners;
    }

    function removeByIndex(uint index) internal onlyOwner {
        if (index >= tempList.length) return;

        for (uint i = index; i < tempList.length - 1; i++) {
            tempList[i] = tempList[i + 1];
        }
        tempList.pop();
    }

    function selectUsersV2() public returns (address[] memory) {
        uint random = getRandomSeed();

        for (uint i = 0; i < numOfwinners; i++) {
            winners.push(tempList[random]);
            countOfwins[tempList[random]]++;
            removeByIndex(random);
            random = recalcuateRandomSeed(random);
        }
        return winners;
    }

    function clearWinners() public onlyOwner returns (address[] memory) {
        for (uint i = 0; i < winners.length; i++) {
            winners.pop();
        }
        return winners;
    }

    function initTemp() public onlyOwner {
        tempList = listOfParticipants;
    }

    // function settlement() external onlyOwner {
    //     for (uint i = 0; i < listOfParticipants.length; i++) {
    //         if (countOfwins[listOfParticipants[i]] != 0) {
    //             //
    //         } else {
    //             //
    //         }
    //     }
    // }
}
