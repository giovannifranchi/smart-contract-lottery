// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployLottery} from "../script/DeployLottery.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription} from "../script/Interactions.s.sol";

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import { Vm } from "forge-std/Vm.sol";

contract LotteryTest is Test {

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed player);

    Lottery public lottery;
    HelperConfig public helperConfig;

    uint256 private USER_AMOUNT = 10 ether;
    address private player = makeAddr("user");

    function setUp() public {
        DeployLottery deployLottery = new DeployLottery();
        (lottery, helperConfig) = deployLottery.run();
        vm.deal(player, USER_AMOUNT);
    }

    function testLotteryIsOpen() public view {
        assert(lottery.getLotteryStatus() == Lottery.LotteryState.OPEN);
    }

    function testEnterLottery() public {
        address payable[] memory prevPlayers = lottery.getPlayersArray();
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        address payable[] memory newPlayers = lottery.getPlayersArray();
        assertEq(newPlayers[0], player);
        assertEq(prevPlayers.length, newPlayers.length - 1);
    }

    function testEntranceDeclainedIfNotValue() public {
        vm.prank(player);
        vm.expectRevert(Lottery.Lottery__NotEnoughETHSend.selector);
        lottery.getEntrance{value: 0.09 ether}();
    }

    function testEmitAtEntrance() public {
        vm.prank(player);
        vm.expectEmit(true, false, false, false, address(lottery));
        emit PlayerEntered(player);
        lottery.getEntrance{value: 0.1 ether}();
    }

    function testDenialWhenClosed() public {
        vm.deal(address(lottery), 20 ether);
        vm.warp(block.timestamp + 30000);
        vm.roll(block.number + 333);
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        lottery.performUpkeep();
        vm.expectRevert(Lottery.Lottery__ClosedEntering.selector);
        lottery.getEntrance{value: 0.1 ether}();
    }

    function testUpkeepWithNoBalance() public {
        vm.warp(block.timestamp + 3000);
        vm.roll(block.number + 333);
        (bool upKeepNeeded,) = lottery.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testUpkeepIfClosed() public {
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        vm.warp(block.timestamp + 30000);
        vm.roll(block.number + 333);
        lottery.performUpkeep();
        (bool upKeepNeeded,) = lottery.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepIfEnoughTimeHasnPassed() public {
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        vm.warp(block.timestamp + 33);
        vm.roll(block.number + 2);
        (bool upKeepNeeded,) = lottery.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testUpkeepWorksWhenParamsAreOk() public {
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        vm.warp(block.timestamp + 30000);
        vm.roll(block.number + 333);
        (bool upKeepNeeded,) = lottery.checkUpkeep("");
        assert(upKeepNeeded);
    }

    function testPerformUpkeepWorksOnlyIfParamsAreOk() public {
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        vm.warp(block.timestamp + 300000);
        vm.roll(block.number + 333);
        lottery.performUpkeep();
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 balance = 0;
        uint256 numPlayers = 0;
        uint256 lotteryStatus = 0;
        vm.expectRevert(abi.encodeWithSelector(Lottery.Lottery__UpkeepNotNeeded.selector,balance, numPlayers, lotteryStatus));
        lottery.performUpkeep();
    }

    //FUZZ TEST
    // function testFulfillRandomWordAlwaysFailsWithNoRequest(uint256 randomId) public{
    //     address vrfCoordinator = helperConfig.getVRFCoordinator();
    //     vm.expectRevert();
    //     VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomId, address(lottery));
    // }

    modifier enteredAndTimeHasPassed(){
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        vm.warp(block.timestamp + 300000);
        _;
    }

    // function testEntireExecutionWorks() public enteredAndTimeHasPassed() {

    //     uint256 numPlayers = 7;
    //     uint256 startingPlayer = 1;


    //     for (uint256 i = startingPlayer; i < numPlayers; i++) {
    //         address temPlayer = address(uint160(i));
    //         vm.deal(temPlayer, 10 ether);
    //         lottery.getEntrance{value: 0.1 ether}();
    //     }

    //     uint256 prevBalance = address(lottery).balance;

    //     (bool upKeepNeeded,) = lottery.checkUpkeep("");


    //     vm.recordLogs();
    //     lottery.performUpkeep(); 
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

    //     VRFCoordinatorV2Mock(helperConfig.getVRFCoordinator()).fulfillRandomWords(uint256(requestId), address(lottery));   


    //     address winner = lottery.getRecentWinner();



        
    //     assert(lottery.getPlayersCount() == 0);
    //     assert(winner != address(0));
    //     assert(lottery.getLotteryStatus() == Lottery.LotteryState.OPEN);
    //     assert(address(lottery).balance == 0);
    //     assert(winner.balance == prevBalance - 0.1 ether + 10 ether);

    // }
}
