// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    using SafeERC20 for IERC20;

    struct ParticipationInfo {
        uint256 totalAmountFrom;
        uint256 totalAmountTo;
    }

    /// @notice total participation amount
    /// e.g. total winner reward
    uint256 public totalAmount;

    /// @notice randomized wining number
    uint256 public winNumber;

    bool public rewardClaimed;

    mapping(address => ParticipationInfo[]) userParicipations;

    address public immutable lotteryToken;
    uint256 public immutable participateStart;
    uint256 public immutable participateEnd;

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
        uint256 _participateStart,
        uint256 _participateDuration
    ) {
        require(_lotteryToken != address(0), "Lottery: invalid _lotteryToken");
        require(_participateStart != 0, "Lottery: invalid _participateStart");
        require(
            _participateDuration != 0,
            "Lottery: invalid _participateDuration"
        );

        lotteryToken = _lotteryToken;
        participateStart = _participateStart;
        participateEnd = _participateStart + _participateDuration;
    }

    function participate(uint256 _tokenAmount)
        external
        returns (uint256 userParticipationId)
    {
        require(_tokenAmount != 0, "Lottery: invalid _tokenAmount");
        require(block.timestamp >= participateStart, "Lottery: not started");
        require(block.timestamp < participateEnd, "Lottery: ended");

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

    function selectRandomWinner() external {
        require(block.timestamp >= participateEnd, "Lottery: not ended");
        require(winNumber == 0, "Lottery: already selected");

        // TODO get random number from VRF
        uint256 _winNumber = 0;

        winNumber = _winNumber;

        emit RandomWinningNumberSelect(msg.sender, _winNumber);
    }

    function getUserParticipations(address user)
        external
        view
        returns (ParticipationInfo[] memory)
    {
        return userParicipations[user];
    }
}
