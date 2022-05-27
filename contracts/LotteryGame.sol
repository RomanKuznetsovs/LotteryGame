//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract LotteryGame {

    address private owner;
    uint256 private lotteryCount;
    uint256 private remainsBalance;

    uint256 constant FEE = 10;
    uint256 constant INCREASEBET = 1;
    uint256 constant DURATION = 1 hours;

    mapping (uint256 => Lottery) lotteries;

    struct Lottery {

        uint256 balance;
        uint256 startingBalance;
        uint256 startTimeCount;
        uint256 finalTime;
        bool isActive;
        address currentLeader;
        address winner;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event LotteryIsCreated(uint256 indexed lotteryId);

    event BetterHasBeted(uint256 indexed lotteryId, address indexed better, uint256 amount);

    event LotteryHasEnded(uint256 indexed lotteryId, address indexed winner, uint256 prize);

    function addLottery () external onlyOwner{
        uint256 lotteryId = lotteryCount++;
        uint _startTimeCount = block.timestamp;
        Lottery storage _lottery = lotteries[lotteryId];

        _lottery.startTimeCount = _startTimeCount;
        _lottery.finalTime = _startTimeCount + DURATION;
        _lottery.startingBalance +=  remainsBalance;

        _lottery.isActive = true; 


        emit LotteryIsCreated(lotteryId);
    }

    function bet(uint256 lotteryId) external payable{
        Lottery storage _lottery = lotteries[lotteryId];
        uint256 _bet = _lottery.balance * INCREASEBET / 100;

        require(_lottery.isActive,"Lottery stopped");
        require(msg.value >= _bet, "Your bet is low then require!");

        _lottery.balance += msg.value;
        _lottery.currentLeader = msg.sender;
        _lottery.finalTime = block.timestamp + DURATION;

        emit BetterHasBeted(lotteryId, msg.sender, msg.value);
    }

    function getBalance(uint256 lotteryId) external view returns(uint256){
        return lotteries[lotteryId].balance;
    } 

    function needBetToWin(uint256 lotteryId) external view returns(uint256){
        return lotteries[lotteryId].balance * INCREASEBET / 100;
    }

    
    function getremainsBalance(uint256) external view returns(uint256){
        return remainsBalance;
    }

        function getIsActive(uint256 lotteryId) external view returns(bool){
        return lotteries[lotteryId].isActive;
    }

        function getTimeRemain(uint256 lotteryId) external view returns(uint256){
            if(lotteries[lotteryId].isActive == false){
                return 0;
            }else if(lotteries[lotteryId].finalTime >= block.timestamp){
                return lotteries[lotteryId].finalTime - block.timestamp;
            }else 
            return 0;
        }

            function getStartingBalance(uint256 lotteryId) external view returns(uint256){
        return lotteries[lotteryId].startingBalance;
    }
        
    function finishLottery(uint256 lotteryId) external{
        Lottery storage _lottery = lotteries[lotteryId];

        require(block.timestamp >= _lottery.finalTime , "Lottery still active ,please bet");

        _lottery.isActive = false;
        _lottery.winner = _lottery.currentLeader;
        uint256 prize = (_lottery.balance * 90) / 100;
        remainsBalance +=_lottery.balance - prize;
        address payable winner = payable(_lottery.winner);
        winner.transfer(prize);

        delete _lottery.balance;

        emit LotteryHasEnded(lotteryId, winner, prize);
    }
}