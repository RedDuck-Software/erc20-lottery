// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "hardhat/console.sol";

contract Lottery {
    using SafeERC20 for IERC20;

    struct ParticipationInfo {
        uint256 totalAmountFrom;
        uint256 totalAmountTo;
    }

    /// @notice total participation amount
    /// e.g. total winner reward
    uint256 public totalAmount;
    uint256 public totalPlayedAmount;
    uint256 public totalParticipants;

    /// @notice randomized wining number
    uint256 public winNumber;
    uint256 public randomWinnerIdx;
    bool public rewardClaimed;

    mapping(address => ParticipationInfo[]) userParicipations;

    address public lotteryToken;
    uint256 public nextParticipateTimestamp;

    uint256 public totalGamesPlayed;
    uint256 public totalPayoutToday;

    address public lastWinner;
    uint256 public lastWonAmount;

    uint256 public interval;
    // uint256 public lastTimeStamp;
    uint256 public randomNumber;

    mapping(address => uint256) winnerBalances;
    address[] public participants;
    event UserParticipate(
        address indexed user,
        uint256 totalAmountFrom,
        uint256 totalAmountTo,
        uint256 userParticipationId
    );

    event WinnerClaim(
        address indexed winner,
        uint256 intervalId,
        uint256 claimAmount
    );

    event RandomWinningNumberSelect(
        address indexed txSender,
        uint256 winningNumber
    );

    constructor(
        address _lotteryToken,
        uint256 _participateInterval
    ) {
        require(_lotteryToken != address(0), "Lottery: invalid _lotteryToken");

        // lastTimeStamp = block.timestamp;
        interval = _participateInterval;

        lotteryToken = _lotteryToken;
        nextParticipateTimestamp = block.timestamp + _participateInterval;
    }

    //10:00 - 10:30 prepare time ,10:30 - lottery,11:00 - 11:30 - prepare time
    function participate(uint256 _tokenAmount)
        external
        returns (uint256 userParticipationId)
    {
        require(_tokenAmount != 0, "Lottery: invalid _tokenAmount");
        require(
            block.timestamp <= nextParticipateTimestamp,
            "Lottery: has already started"
        );

        IERC20(lotteryToken).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        uint256 _totalAmount = totalAmount;
        uint256 _newTotalAmount = _totalAmount + _tokenAmount;

        ParticipationInfo memory participation = ParticipationInfo({
            totalAmountFrom: _totalAmount + 1,
            totalAmountTo: _newTotalAmount
        });

        totalAmount = _newTotalAmount;

        userParticipationId = userParicipations[msg.sender].length;

        userParicipations[msg.sender].push(participation);

        participants.push(msg.sender);

        emit UserParticipate(
            msg.sender,
            participation.totalAmountFrom,
            participation.totalAmountTo,
            userParticipationId
        );
    }

    function claimWinnerReward(address _winner, uint256 _winnerIntervalId)
        external
        returns (uint256 amountToClaim)
    {
        require(!rewardClaimed, "Lottery: reward already claimed");

        uint256 _winNumber = winNumber;

        require(_winNumber != 0, "Lottery: random winner not selected");
        require(
            userParicipations[_winner].length > _winnerIntervalId,
            "Lottery: invalid interval id"
        );

        ParticipationInfo memory winnerParticipation = userParicipations[
            _winner
        ][_winnerIntervalId];

        require(
            _winNumber >= winnerParticipation.totalAmountFrom &&
                _winNumber <= winnerParticipation.totalAmountTo,
            "Lottery: invalid winner"
        );

        amountToClaim = totalAmount;
        rewardClaimed = true;

        IERC20(lotteryToken).transfer(_winner, amountToClaim);

        emit WinnerClaim(_winner, _winnerIntervalId, amountToClaim);
    }

    function generateRandomNumber(uint256 participants)public returns(uint256){
        randomWinnerIdx = uint256(keccak256(
            abi.encodePacked(msg.sender,block.difficulty,block.timestamp)
        )) % participants;
        console.log('randomWinnerIdx',randomWinnerIdx);
        return randomWinnerIdx;
    }

    function selectRandomWinner() external {
        require(
            block.timestamp >= nextParticipateTimestamp,
            "Lottery: !nextParticipateTimestamp"
        );

        if (participants.length == 0) {
            nextParticipateTimestamp = block.timestamp + interval;
        } else {
            
            uint256 _winNumber = generateRandomNumber(participants.length);
            nextParticipateTimestamp = block.timestamp + interval;

            totalGamesPlayed += 1;
            address winner;
            if(_winNumber == 0){
                winner = participants[0];
            } else {
                winner = participants[_winNumber-1];
            }
            winnerBalances[winner] = totalAmount;

            lastWinner=winner;
            lastWonAmount = totalAmount;
            
            participants = new address[](0);
            totalAmount=0;
            emit RandomWinningNumberSelect(msg.sender, _winNumber);
        }
    }


    function getUserParticipations(address user)
        external
        view
        returns (ParticipationInfo[] memory)
    {
        return userParicipations[user];
    }

    function getCurrect() public view returns (uint256) {
        return block.timestamp;
    }
}
