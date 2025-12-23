// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {YVaultWrapper} from "contracts/wrappers/YVaultWrapper.sol";

/// @notice Deploys a YVaultWrapper and adds it to MultiWrapper.
contract DeployYVaultWrapper is Script {
    function run() external returns (YVaultWrapper wrapper) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();

        vm.startBroadcast();
        wrapper = new YVaultWrapper();
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
