// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {Erc4626Wrapper} from "contracts/wrappers/Erc4626Wrapper.sol";

/// @notice Deploys an Erc4626Wrapper and adds it to MultiWrapper; vaults passed via env.
contract DeployErc4626Wrapper is Script {
    function run() external returns (Erc4626Wrapper wrapper) {
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        address[] memory markets =
            vm.parseJsonAddressArray(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.markets"));
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast();
        wrapper = new Erc4626Wrapper(owner);
        wrapper.addMarkets(markets);
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
