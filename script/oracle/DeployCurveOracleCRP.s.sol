// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {CurveOracleCRP} from "contracts/oracles/CurveOracleCRP.sol";
import {ICurveProvider} from "contracts/interfaces/ICurveProvider.sol";

contract DeployCurveOracleCRP is Script {
    function run() external returns (CurveOracleCRP oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address provider = vm.envAddress("PROVIDER");
        uint256 maxPools = vm.envUint("MAXPOOLS");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // Curve treated as WETH by default

        vm.startBroadcast();
        oracle = new CurveOracleCRP{salt: salt}(ICurveProvider(provider), maxPools);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
