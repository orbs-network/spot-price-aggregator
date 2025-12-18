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
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address base = vm.envAddress("BASE");
        address wbase = vm.envAddress("WBASE");

        vm.startBroadcast();
        wrapper = new BaseCoinWrapper{salt: salt}(IERC20(base), IERC20(wbase));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
