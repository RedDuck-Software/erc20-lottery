// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "./LotteryVRFConsumer.sol";
import "hardhat/console.sol";

contract Lottery is AutomationCompatible {
    using SafeERC20 for IERC20;

    LotteryVRFConsumer internal lotteryVRFConsumer;

    address public lotteryToken;

    uint256 public interval;
    uint256 public nextParticipateTimestamp;

    mapping(address => uint256) public usersContractBalance;

    uint256 public totalPrizePool;
    uint256 public totalAllTimePrizePool;
    uint256 public totalGamesPlayed;
    uint256 public lastWonAmount;

    address public lastWinner;

    struct ParticipantsInfo {
        address participantAddress;
        uint256 depositedAmount;
        uint256 startPoint; // totalPrizePool before user deposited tokens
        uint256 endPoint; // totalPrizePool + depositedAmount
    }

    struct WinnersInfo {
        address winnerAddress;
        uint256 wonAmount;
    }

    ParticipantsInfo[] private participants;
    WinnersInfo[] private winners;

    event WinnerSelect(address indexed winner, uint256 indexed wonAmount);

    constructor(
        address _lotteryToken,
        uint256 _participateInterval,
        address _lotteryVRFAddr
    ) {
        require(_lotteryToken != address(0), "Lottery: invalid _lotteryToken");

        interval = _participateInterval;
        lotteryToken = _lotteryToken;
        nextParticipateTimestamp = block.timestamp + _participateInterval;
        lotteryVRFConsumer = LotteryVRFConsumer(_lotteryVRFAddr);
    }

    function deposit(uint256 tokenAmount) external {
        require(tokenAmount != 0, "Lottery: invalid tokenAmount");

        IERC20(lotteryToken).safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );

        usersContractBalance[msg.sender] += tokenAmount;
    }

    function withdraw(uint256 _tokenAmount) external {
        require(
            usersContractBalance[msg.sender] >= _tokenAmount,
            "Lottery: no enough balance"
        );
        IERC20(lotteryToken).transfer(msg.sender, _tokenAmount);

        usersContractBalance[msg.sender] -= _tokenAmount;
    }

    function participate(uint256 _tokenAmount) external {
        require(_tokenAmount > 0, "Lottery: invalid tokenAmount");
        require(
            block.timestamp <= nextParticipateTimestamp,
            "Lottery: has already started"
        );
        require(
            usersContractBalance[msg.sender] >= _tokenAmount,
            "Lottery:insufficient balance"
        );

        participants.push(
            ParticipantsInfo(
                msg.sender,
                _tokenAmount,
                totalPrizePool,
                totalPrizePool + _tokenAmount
            )
        );
        totalPrizePool = totalPrizePool + _tokenAmount;
        usersContractBalance[msg.sender] -= _tokenAmount;
        totalAllTimePrizePool += _tokenAmount;
    }

    function selectRandomWinner() internal {
        if (participants.length == 0) {
            nextParticipateTimestamp = block.timestamp + interval;
        } else {
            address winner = getWinnerAddress();
            nextParticipateTimestamp = block.timestamp + interval;

            winners.push(WinnersInfo(winner, totalPrizePool));

            usersContractBalance[winner] += totalPrizePool;
            lastWinner = winner;
            lastWonAmount = totalPrizePool;
            totalGamesPlayed += 1;

            emit WinnerSelect(winner, totalPrizePool);

            delete participants;
            delete totalPrizePool;
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = block.timestamp >= nextParticipateTimestamp;
    }

    function performUpkeep(bytes calldata performData) external override {
        (bool isUpkeepNeeded, ) = checkUpkeep(performData);
        require(isUpkeepNeeded, "Lottery: No need to upkeep");
        selectRandomWinner();
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getParticipants() public view returns (ParticipantsInfo[] memory) {
        return participants;
    }

    function getAllWinners() public view returns (WinnersInfo[] memory) {
        return winners;
    }

    function getWinnerAddress() internal returns (address) {
        lotteryVRFConsumer.requestRandomWords();
        uint256 winningNumber = lotteryVRFConsumer.getRandomNumber(
            totalPrizePool
        );

        address winner;

        for (uint256 i = 0; i <= participants.length; i++) {
            bool isWinner = winningNumber >= participants[i].startPoint &&
                winningNumber <= participants[i].endPoint;

            if (isWinner) {
                winner = participants[i].participantAddress;
                break;
            }
        }
        return winner;
    }
}
