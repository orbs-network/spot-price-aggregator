// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {CompoundV3Wrapper} from "contracts/wrappers/CompoundV3Wrapper.sol";

/// @notice Deploys a CompoundV3Wrapper and adds it to MultiWrapper; markets passed via env.
contract DeployCompoundV3Wrapper is Script {
    function run() external returns (CompoundV3Wrapper wrapper) {
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address[] memory markets = vm.envAddress("MARKETS", ",");
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast();
        wrapper = new CompoundV3Wrapper{salt: salt}(owner);
        wrapper.addMarkets(markets);
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
