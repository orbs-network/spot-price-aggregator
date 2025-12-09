// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SolidlyOracle} from "contracts/oracles/SolidlyOracle.sol";

contract DeploySolidlyOracle is Script {
    function run() external returns (SolidlyOracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        bytes32 initcodeHash = vm.envBytes32("INITCODEHASH");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new SolidlyOracle{salt: salt}(factory, initcodeHash);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
