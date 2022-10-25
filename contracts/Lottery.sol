pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "hardhat/console.sol";

contract Lottery {
    using SafeERC20 for IERC20;

    // struct ParticipationInfo {
    //     uint256 totalAmountFrom;
    //     uint256 totalAmountTo;
    // }

    /// @notice total participation amount
    /// e.g. total winner reward
    uint256 public totalPrizePool;
    uint256 public totalPlayedAmount;
    uint256 public totalParticipants;
    uint256 public totalAllTimePrizePool;
    uint256 public totalGamesPlayed;
    uint256 public totalPayoutToday;
    address public lastWinner;
    uint256 public lastWonAmount;

    /// @notice randomized wining number
    uint256 public winNumber;
    uint256 public randomWinnerIdx;
    bool public rewardClaimed;

    // mapping(address => ParticipationInfo[]) userParicipations;
    mapping(address => uint256) public usersContractBalance;

    address public lotteryToken;
    uint256 public nextParticipateTimestamp;

    uint256 public interval;
    // uint256 public lastTimeStamp;
    uint256 public randomNumber;

    mapping(address => uint256) winnerBalances;
    address[] public participants;

    event WinnerClaim(
        address indexed winner,
        uint256 intervalId,
        uint256 claimAmount
    );

    event RandomWinningNumberSelect(
        address indexed txSender,
        uint256 winningNumber
    );

    constructor(address _lotteryToken, uint256 _participateInterval) {
        require(_lotteryToken != address(0), "Lottery: invalid _lotteryToken");

        // lastTimeStamp = block.timestamp;
        interval = _participateInterval;

        lotteryToken = _lotteryToken;
        nextParticipateTimestamp = block.timestamp + _participateInterval;
    }

    function deposit(uint256 tokenAmount) external {
        require(tokenAmount != 0, "Lottery: invalid tokenAmount");

        IERC20(lotteryToken).safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );

        usersContractBalance[msg.sender] = tokenAmount;
    }

    function withdraw(uint256 _tokenAmount) external {
        uint256 usersBalance = usersContractBalance[msg.sender];

        require(usersBalance >= _tokenAmount, "Lottery: no enough balance");

        IERC20(lotteryToken).safeTransferFrom(
            address(this),
            msg.sender,
            usersBalance
        );

        usersContractBalance[msg.sender] = usersBalance - _tokenAmount;
    }

    //10:00 - 10:30 prepare time ,10:30 - lottery,11:00 - 11:30 - prepare time
    function participate(uint256 tokenAmount)
        external
        returns (uint256 userParticipationId)
    {
        uint256 userBalance = usersContractBalance[msg.sender];

        require(tokenAmount > 0, "Lottery: invalid tokenAmount");
        require(
            block.timestamp <= nextParticipateTimestamp,
            "Lottery: has already started"
        );
        require(userBalance >= tokenAmount, "Lottery:insufficient balance");

        usersContractBalance[msg.sender] = userBalance - tokenAmount;
        totalPrizePool = totalPrizePool + tokenAmount;
        participants.push(msg.sender);
        totalAllTimePrizePool = totalAllTimePrizePool + tokenAmount;
    }

    function generateRandomNumber(uint256 _participants)
        public
        returns (uint256)
    {
        randomWinnerIdx =
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.difficulty,
                        block.timestamp
                    )
                )
            ) %
            _participants;

        return randomWinnerIdx;
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
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

            address winner;

            if (_winNumber == 0) {
                winner = participants[0];
            } else {
                winner = participants[_winNumber - 1];
            }

            uint256 userBalance = usersContractBalance[winner];
            usersContractBalance[winner] = userBalance + totalPrizePool;

            lastWinner = winner;
            lastWonAmount = totalPrizePool;

            participants = new address[](0);
            totalPrizePool = 0;
            totalGamesPlayed += 1;

            emit RandomWinningNumberSelect(msg.sender, _winNumber);
        }
    }

    function getCurrect() public view returns (uint256) {
        return block.timestamp;
    }
}
