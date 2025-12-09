// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {AlgebraOracle} from "contracts/oracles/AlgebraOracle.sol";

contract DeployAlgebraOracle is Script {
    function run() external returns (AlgebraOracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        bytes32 initcodeHash = vm.envBytes32("INITCODEHASH");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new AlgebraOracle{salt: salt}(factory, initcodeHash);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
