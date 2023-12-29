// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 pricePerEntrance;//
        uint256 timeInterval;//
        address vrfCoordinator;//
        bytes32 keyHash;//
        uint64 subId;//
        uint16 minimumRequestConfirmations;
        uint32 callbackGasLimit;//
        uint32 numWords;
        address link;
        uint256 privateKey;
    }

    NetworkConfig public activeNetworkConfig;

    uint256 private immutable ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public  returns (NetworkConfig memory sepoliaConfig) {
        return sepoliaConfig = NetworkConfig({
            pricePerEntrance: 0.1 ether,
            timeInterval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 8146,
            minimumRequestConfirmations: 2,
            callbackGasLimit: 500000,
            numWords: 1,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            privateKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory anvilConfig) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        } else {
            uint96 BASE_FEE = 0.25 ether; // are actually Link tokens
            uint96 GAS_PRICE_LINK = 0.0000000001 ether; // are actually Link tokens repaid for
            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
            LinkToken linkToken = new LinkToken();
            vm.stopBroadcast();
            return anvilConfig = NetworkConfig({
                pricePerEntrance: 0.1 ether,
                timeInterval: 30,
                vrfCoordinator: address(vrfCoordinator),
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subId: 0,
                minimumRequestConfirmations: 2,
                callbackGasLimit: 500000,
                numWords: 1,
                link: address(linkToken),
                privateKey: ANVIL_PRIVATE_KEY
            });
        }
    }
}
