// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "hardhat/console.sol";

contract LotteryVRFConsumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    /// @dev VRF Coordinator: Goerli testnet (https://docs.chain.link/docs/vrf-contracts/#configurations)
    address private constant vrfCoordinator =
        0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint64 s_subscriptionId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = _subscriptionId;
    }

    function requestRandomWords() public {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function getRandomNumber(uint256 maxNumber) public view returns (uint256) {
        uint256 randomNumber = (s_randomWords[0] % maxNumber) + 1;
        return randomNumber;
    }
}
