// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SynthetixOracle} from "contracts/oracles/SynthetixOracle.sol";
import {ISynthetixProxy} from "contracts/interfaces/ISynthetixProxy.sol";

contract DeploySynthetixOracle is Script {
    function run() external returns (SynthetixOracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address proxy = vm.envAddress("PROXY");
        uint256 oracleType = vm.envOr("TYPE", uint256(1)); // Synthetix uses native oracle style

        vm.startBroadcast();
        oracle = new SynthetixOracle{salt: salt}(ISynthetixProxy(proxy));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
