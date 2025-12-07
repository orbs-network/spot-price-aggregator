// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {CurveOracle} from "contracts/oracles/CurveOracle.sol";
import {ICurveProvider} from "contracts/interfaces/ICurveProvider.sol";

contract DeployCurveOracle is Script {
    function run() external {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address provider = vm.envAddress("PROVIDER");
        uint256 maxPools = vm.envUint("MAXPOOLS");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // Curve treated as WETH by default

        vm.startBroadcast();
        CurveOracle oracle = new CurveOracle{salt: salt}(ICurveProvider(provider), maxPools);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();

        console.log("OffchainOracle:", address(oc));
        console.log("Curve provider:", provider);
        console.log("Max pools inspected:", maxPools);
        console.log("Oracle type:", oracleType);
        console.log("CurveOracle deployed at:", address(oracle));
    }
}
