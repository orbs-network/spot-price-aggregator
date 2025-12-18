// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {YVaultWrapper} from "contracts/wrappers/YVaultWrapper.sol";

/// @notice Deploys a YVaultWrapper and adds it to MultiWrapper.
contract DeployYVaultWrapper is Script {
    function run() external returns (YVaultWrapper wrapper) {
        OffchainOracle offchainOracle = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        MultiWrapper multiWrapper = offchainOracle.multiWrapper();

        vm.startBroadcast();
        wrapper = new YVaultWrapper{salt: salt}();
        multiWrapper.addWrapper(wrapper);
        vm.stopBroadcast();
    }
}
