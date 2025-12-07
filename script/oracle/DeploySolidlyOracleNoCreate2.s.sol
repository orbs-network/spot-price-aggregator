// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SolidlyOracleNoCreate2} from "contracts/oracles/SolidlyOracleNoCreate2.sol";

contract DeploySolidlyOracleNoCreate2 is Script {
    function run() external {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        SolidlyOracleNoCreate2 oracle = new SolidlyOracleNoCreate2{salt: salt}(factory);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();

        console.log("OffchainOracle:", address(oc));
        console.log("Solidly factory:", factory);
        console.log("Oracle type:", oracleType);
        console.log("SolidlyOracleNoCreate2 deployed at:", address(oracle));
    }
}
