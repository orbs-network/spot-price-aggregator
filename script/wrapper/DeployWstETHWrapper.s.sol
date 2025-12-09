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
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address base = vm.envAddress("BASE");
        address wbase = vm.envAddress("WBASE"); // wstETH

        vm.startBroadcast();
        wrapper = new WstETHWrapper{salt: salt}(IERC20(base), IERC20(wbase));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
