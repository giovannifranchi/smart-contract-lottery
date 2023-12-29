// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title Lottery
/// @author Giovanni Franchi
/// @notice A simple contract that implements a lottery with VRN
/// @dev Explain to a developer any extra details

contract Lottery is VRFConsumerBaseV2 {
    error Lottery__NotEnoughETHSend();
    error Lottery__NotEnoughTimePassed();
    error Lottery__TrasnferFailed();
    error Lottery__ClosedEntering();
    error Lottery__UpkeepNotNeeded(uint256 balance, uint256 players, LotteryState lotteryStatus);

    event PlayerEntered(address indexed player);
    event PickedWinner(address indexed winner);

    // Type Declarations
    enum LotteryState {
        OPEN,
        CLOSED
    }

    // State Variables
    uint256 private immutable i_pricePerEntrance;
    uint256 private immutable i_timeInterval;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;
    uint16 private immutable i_minimumRequestConfirmations;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable i_numWords;

    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    address payable[] private s_players;
    LotteryState private s_lotteryStatus;

    modifier enoughETH() {
        if (msg.value < i_pricePerEntrance) {
            revert Lottery__NotEnoughETHSend();
        }
        _;
    }

    modifier hasTimePassed() {
        if (block.timestamp < s_lastTimestamp + i_timeInterval) {
            revert Lottery__NotEnoughTimePassed();
        }
        _;
    }

    modifier isLotteryOpen() {
        if (s_lotteryStatus != LotteryState.OPEN) {
            revert Lottery__ClosedEntering();
        }
        _;
    }

    constructor(
        uint256 _pricePerEntrance,
        uint256 _timeInterval,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subId,
        uint16 _minimumRequestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_pricePerEntrance = _pricePerEntrance;
        i_timeInterval = _timeInterval;
        s_lastTimestamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subId = _subId;
        i_minimumRequestConfirmations = _minimumRequestConfirmations;
        i_callbackGasLimit = _callbackGasLimit;
        i_numWords = _numWords;
        s_lotteryStatus = LotteryState.OPEN;
    }

    function getEntrance() external payable enoughETH isLotteryOpen {
        s_players.push(payable(msg.sender));

        emit PlayerEntered(msg.sender);
    }

    function checkUpkeep(bytes memory)
        public
        /**
         * calldata
         */
        view
        returns (bool upkeepNeeded, bytes memory)
    /**
     * performData
     */
    {
        bool timeHasPassed = block.timestamp > s_lastTimestamp;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        bool isOpen = s_lotteryStatus == LotteryState.OPEN;
        upkeepNeeded = timeHasPassed && hasBalance && hasPlayers && isOpen;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep() external {
        (bool upkeepNeeded,) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(address(this).balance, s_players.length, s_lotteryStatus);
        }

        s_lotteryStatus = LotteryState.CLOSED;

        i_vrfCoordinator.requestRandomWords(
            i_keyHash, i_subId, i_minimumRequestConfirmations, i_callbackGasLimit, i_numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_lotteryStatus = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        (bool success,) = winner.call{value: address(this).balance}("");

        if (!success) {
            revert Lottery__TrasnferFailed();
        }

        emit PickedWinner(winner);
    }

    function getLotteryStatus() external view returns (LotteryState) {
        return s_lotteryStatus;
    }

    function getPlayersArray() external view returns (address payable[] memory) {
        return s_players;
    }
}
