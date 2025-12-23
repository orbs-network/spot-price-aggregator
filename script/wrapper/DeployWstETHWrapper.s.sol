// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {WstETHWrapper} from "contracts/wrappers/WstETHWrapper.sol";

/// @notice Deploys a WstETHWrapper via CREATE2 and adds it to an existing MultiWrapper.
contract DeployWstETHWrapper is Script {
    function run() external returns (WstETHWrapper wrapper) {
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address base =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.base"));
        address wbase =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.wbase")); // wstETH

        vm.startBroadcast();
        wrapper = new WstETHWrapper{salt: salt}(IERC20(base), IERC20(wbase));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
