// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";


contract DeployLottery is Script {
    function run() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 pricePerEntrance,
            uint256 timeInterval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subId,
            uint16 minimumRequestConfirmations,
            uint32 callbackGasLimit,
            uint32 numWords,
            address link,
            uint256 privateKey
        ) = helperConfig.activeNetworkConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrfCoordinator);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subId, link, privateKey);
        }

        vm.startBroadcast();
        Lottery lottery = new Lottery(
            pricePerEntrance,
            timeInterval,
            vrfCoordinator,
            keyHash,
            subId,
            minimumRequestConfirmations,
            callbackGasLimit,
            numWords
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(lottery), vrfCoordinator, subId);

        return (lottery, helperConfig);
    }
}
