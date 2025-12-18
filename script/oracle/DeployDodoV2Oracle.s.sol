// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {DodoV2Oracle} from "contracts/oracles/DodoV2Oracle.sol";
import {IDVMFactory} from "contracts/interfaces/IDodoFactories.sol";

contract DeployDodoV2Oracle is Script {
    function run() external returns (DodoV2Oracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new DodoV2Oracle{salt: salt}(IDVMFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
