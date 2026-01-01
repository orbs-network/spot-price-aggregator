// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {CompoundV3Wrapper} from "contracts/wrappers/CompoundV3Wrapper.sol";

/// @notice Deploys a CompoundV3Wrapper and adds it to MultiWrapper; markets passed via env.
contract DeployCompoundV3Wrapper is Script {
    function run() external returns (CompoundV3Wrapper wrapper) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address[] memory markets =
            vm.parseJsonAddressArray(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.markets"));
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast();
        wrapper = new CompoundV3Wrapper(owner);
        wrapper.addMarkets(markets);
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
