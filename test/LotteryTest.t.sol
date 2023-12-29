// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployLottery} from "../script/DeployLottery.s.sol";
import {Test} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription} from "../script/Interactions.s.sol";

contract LotteryTest is Test {
    event PlayerEntered(address indexed player);

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
        vm.warp(block.timestamp + 3000);
        vm.roll(block.number + 333);
        vm.prank(player);
        lottery.getEntrance{value: 0.1 ether}();
        lottery.performUpkeep();
        vm.expectRevert(Lottery.Lottery__ClosedEntering.selector);
        lottery.getEntrance{value: 0.1 ether}();
    }
}
