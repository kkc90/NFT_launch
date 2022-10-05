// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Raffle is Ownable {
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

    constructor() {
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
        seed = uint256(keccak256(abi.encodePacked(block.timestamp))) % listOfParticipants.length;
        return seed;
    }
    
    function recalcuateRandomSeed(uint256 selected) internal view onlyOwner returns (uint256) {
        return uint256(keccak256(abi.encodePacked(selected++))) % tempList.length;
    }

    function selectUsers() public returns (address[] memory){
        uint random = getRandomSeed();

        do {
            if (listOfParticipants[random] != address(0) ) {
                winners.push(listOfParticipants[random]);
                listOfParticipants[random] = address(0) ;
            } else {
                random = recalcuateRandomSeed(random);
            }
        } while (winners.length != numOfwinners);

        return winners;
    }

    function removeByIndex(uint index) internal onlyOwner{
        if (index >= tempList.length) return;

        for (uint i = index; i < tempList.length-1; i++) {
            tempList[i] = tempList[i+1];
        }
        tempList.pop();
    }

    function selectUsersV2() public returns (address[] memory){
        uint random = getRandomSeed();

        for (uint i = 0; i < numOfwinners; i++){
            winners.push(listOfParticipants[random]);
            removeByIndex(random);
            random = recalcuateRandomSeed(random);
        }
        return winners;
    }

    function clearWinners() public onlyOwner returns (address[] memory){
        for (uint i = 0; i < winners.length; i++) {
            winners.pop();
        }
        return winners;
    }

    function clearTemp() public onlyOwner returns (address[] memory){
        for (uint i = 0; i < tempList.length; i++) {
            tempList.pop();
        }
        return tempList;
    }
}