//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @author RomanKuznetsovs
/// @title Lottery with prize for the winner and commission for the next lottery.
contract LotteryGame is ReentrancyGuard {

    address public owner;
    uint256 private lotteryCount;
    uint256 private remainsBalance;

    uint256 constant public FEE = 10;
    uint256 constant public INCREASEBET = 1;
    uint256 constant public DURATION = 1 hours;

    mapping (uint256 => Lottery) lotteries;

    struct Lottery {

        uint256 balance;
        uint256 startingBalance;
        uint256 lotteryTime;
        bool isActive;
        address winner;
    }

    uint[] public lotteryItem;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @notice Gets triggered upon creation of a new lottery by the owner.
    event LotteryIsCreated(uint256 indexed lotteryId);

    /// @notice Gets triggered upon a successful bet by the owner.
    event BetterHasBetted(uint256 indexed lotteryId, address indexed better, uint256 amount);

    /// @notice Gets triggered upon a succcessful finish of a lottery.
    event LotteryHasEnded(uint256 indexed lotteryId, address indexed winner, uint256 prize);

    /// @notice Start the lottery.
    /// @dev Each consequent lottery has an index incremented by 1 starting at 0.
    function addLottery () external onlyOwner{
        require(lotteryItem.length == lotteryCount, "Please wait to end previous lottery!");

        uint256 lotteryId = lotteryCount++;
        uint256 _lotteryTime = block.timestamp;
        Lottery storage _lottery = lotteries[lotteryId];

        _lottery.lotteryTime = _lotteryTime + DURATION;
        _lottery.startingBalance +=  remainsBalance;

        _lottery.isActive = true;

        emit LotteryIsCreated(lotteryId);
    }

    /// @notice Bet in lottery.
    /// @param lotteryId Integer which represents index of the lottery.
    /// @dev Take notice of multiple require statements.
    ///      Each next bet needto increment on 0.1% than previous bet.
    ///      Lottery time should increment on 1 hours.
    ///      You can start only one lottery at the same time.
    function bet(uint256 lotteryId) external payable{
        Lottery storage _lottery = lotteries[lotteryId];
        uint256 _bet = _lottery.balance * INCREASEBET / 100;

        require(_lottery.isActive,"Lottery stopped");
        require(msg.value >= _bet, "Your bet is low then require!");

        _lottery.balance += msg.value;
        _lottery.winner = msg.sender;
        _lottery.lotteryTime = block.timestamp + DURATION;

        emit BetterHasBetted(lotteryId, msg.sender, msg.value);
    }

    /// @notice Current balance.
    /// @param lotteryId Integer which represents index of the lottery.
    function getBalance(uint256 lotteryId) external view returns(uint256){
        return lotteries[lotteryId].balance;
    }

    /// @notice Current amount need to bet.
    /// @param lotteryId Integer which represents index of the lottery.
    function needBetToWin(uint256 lotteryId) external view returns(uint256){
        return lotteries[lotteryId].balance * INCREASEBET / 100;
    }

    /// @notice Current remain balance.
    function getRemainsBalance(uint256) external view returns(uint256){
        return remainsBalance;
    }

    /// @notice Current status of lottery.
    /// @param lotteryId Integer which represents index of the lottery.
    function getIsActive(uint256 lotteryId) external view returns(bool){
        return lotteries[lotteryId].isActive;
    }

    /// @notice Current time until teh end of lottery.
    /// @param lotteryId Integer which represents index of the lottery.
    function getTimeRemain(uint256 lotteryId) external view returns(uint256){
        if(!lotteries[lotteryId].isActive){
            return 0;
        }else if(lotteries[lotteryId].lotteryTime >= block.timestamp){
            return lotteries[lotteryId].lotteryTime - block.timestamp;
        }else{
            return 0;
        }
    }

    /// @notice Current time until teh end of lottery.
    /// @param lotteryId Integer which represents index of the lottery.
    function getStartingBalance(uint256 lotteryId) external view returns(uint256){
        return lotteries[lotteryId].startingBalance;
    }

    /// @notice Finish lottery.
    /// @param lotteryId Integer which represents index of the lottery.
    /// @dev Take notice of multiple require statement.
    ///      The remaining balance is 10% of the winnings.
    function finishLottery(uint256 lotteryId) external nonReentrant{
        Lottery storage _lottery = lotteries[lotteryId];

        require(block.timestamp >= _lottery.lotteryTime, "Lottery still active please bet");

        _lottery.isActive = false;
        lotteryItem.push(lotteryId);
        uint256 prize = (_lottery.balance * 90) / 100;
        remainsBalance += _lottery.balance - prize;
        address payable winner = payable(_lottery.winner);

        emit LotteryHasEnded(lotteryId, winner, prize);
        winner.transfer(prize);

        delete _lottery.balance;

    }
}