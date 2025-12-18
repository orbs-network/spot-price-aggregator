// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChaiPot} from "contracts/interfaces/IChai.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {ChaiWrapper} from "contracts/wrappers/ChaiWrapper.sol";

/// @notice Deploys a ChaiWrapper via CREATE2 and adds it to an existing MultiWrapper.
contract DeployChaiWrapper is Script {
    function run() external returns (ChaiWrapper wrapper) {
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();
        address base = vm.envAddress("CHAI_BASE"); // usually DAI
        address token = vm.envAddress("CHAI_TOKEN"); // CHAI
        address pot = vm.envAddress("CHAI_POT");

        vm.startBroadcast();
        wrapper = new ChaiWrapper{salt: salt}(IERC20(base), IERC20(token), IChaiPot(pot));
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
