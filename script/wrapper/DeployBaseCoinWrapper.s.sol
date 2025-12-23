// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {BaseCoinWrapper} from "contracts/wrappers/BaseCoinWrapper.sol";

/// @notice Deploys a BaseCoinWrapper via CREATE2 and adds it to an existing MultiWrapper.
contract DeployBaseCoinWrapper is Script {
    function run() external returns (BaseCoinWrapper wrapper) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle offchainOracle = OffchainOracle(aggregator);
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address base =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.base"));
        address wbase =
            vm.parseJsonAddress(json, string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.wbase"));

        vm.startBroadcast();
        wrapper = new BaseCoinWrapper(IERC20(base), IERC20(wbase));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
