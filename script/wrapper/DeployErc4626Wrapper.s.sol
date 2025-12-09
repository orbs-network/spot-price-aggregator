// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {Erc4626Wrapper} from "contracts/wrappers/Erc4626Wrapper.sol";

/// @notice Deploys an Erc4626Wrapper and adds it to MultiWrapper; vaults passed via env.
contract DeployErc4626Wrapper is Script {
    function run() external returns (Erc4626Wrapper wrapper) {
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address[] memory markets = vm.envAddress("MARKETS", ",");
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast();
        wrapper = new Erc4626Wrapper{salt: salt}(owner);
        wrapper.addMarkets(markets);
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
