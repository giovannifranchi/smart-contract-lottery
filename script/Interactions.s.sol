// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() public returns (uint64) {
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,,,,,,uint256 privateKey) = helperConfig.activeNetworkConfig();
        return VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
    }

    function createSubscription(address vrfCoordinator, uint256 privateKey) public returns (uint64 subId) {
        vm.startBroadcast(privateKey);
        subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        return subId;
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionWithConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,uint64 subId,,,, address link, uint256 privateKey ) =
            helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link, privateKey);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link, uint256 privateKey) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(privateKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(privateKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionWithConfig();
    }
}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address lottery) public {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subId,,,,,) =
        helperConfig.activeNetworkConfig();
        addConsumer(lottery, vrfCoordinator, subId);
    }

    function addConsumer(address lottery, address vrfCoordinator, uint64 subId) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, lottery);
        vm.stopBroadcast();
    }

    function run() public {
        address lottery = DevOpsTools.get_most_recent_deployment("Lottery", block.chainid);
        addConsumerUsingConfig(lottery);
    }
}
