pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./LotteryVRFConsumer.sol";
import "hardhat/console.sol";

contract Lottery is AutomationCompatible {
    using SafeERC20 for IERC20;

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

    /// @dev VRF Coordinator: Goerli testnet (https://docs.chain.link/docs/vrf-contracts/#configurations)
    address private constant vrfCoordinator =
        0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    LotteryVRFConsumer internal lotteryVRFConsumer;

    /// @notice total participation amount
    uint256 public totalPrizePool;
    uint256 public totalPlayedAmount;
    uint256 public totalParticipants;
    uint256 public totalAllTimePrizePool;
    uint256 public totalGamesPlayed;
    uint256 public totalPayoutToday;
    address public lastWinner;
    uint256 public lastWonAmount;

    // mapping(address => ParticipationInfo[]) userParicipations;
    mapping(address => uint256) public usersContractBalance;

    address public lotteryToken;
    uint256 public nextParticipateTimestamp;

    uint256 public interval;
    uint256 public randomNumber;

    mapping(address => uint256) winnerBalances;

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

        usersContractBalance[msg.sender] = tokenAmount;
    }

    function withdraw(uint256 _tokenAmount) external {
        uint256 usersBalance = usersContractBalance[msg.sender];

        require(usersBalance >= _tokenAmount, "Lottery: no enough balance");

        IERC20(lotteryToken).transfer(msg.sender, _tokenAmount);

        usersContractBalance[msg.sender] = usersBalance - _tokenAmount;
    }

    //10:00 - 10:30 prepare time ,10:30 - lottery,11:00 - 11:30 - prepare time
    function participate(uint256 _tokenAmount)
        external
        returns (uint256 userParticipationId)
    {
        uint256 userBalance = usersContractBalance[msg.sender];

        require(_tokenAmount > 0, "Lottery: invalid tokenAmount");
        require(
            block.timestamp <= nextParticipateTimestamp,
            "Lottery: has already started"
        );
        require(userBalance >= _tokenAmount, "Lottery:insufficient balance");

        participants.push(
            ParticipantsInfo(
                msg.sender,
                _tokenAmount,
                totalPrizePool,
                totalPrizePool + _tokenAmount
            )
        );
        totalPrizePool = totalPrizePool + _tokenAmount;
        usersContractBalance[msg.sender] = userBalance - _tokenAmount;
        totalAllTimePrizePool = totalAllTimePrizePool + _tokenAmount;
    }

    function getParticipants() public view returns (ParticipantsInfo[] memory) {
        return participants;
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

    function getCurrect() public view returns (uint256) {
        return block.timestamp;
    }

    function getAllWinners() public view returns (WinnersInfo[] memory) {
        return winners;
    }

    function getWinnerAddress() internal view returns (address) {
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
