// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {DodoOracle} from "contracts/oracles/DodoOracle.sol";
import {IDodoZoo} from "contracts/interfaces/IDodoFactories.sol";

contract DeployDodoOracle is Script {
    function run() external {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address zoo = vm.envAddress("ZOO");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        DodoOracle oracle = new DodoOracle{salt: salt}(IDodoZoo(zoo));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();

        console.log("OffchainOracle:", address(oc));
        console.log("DODO Zoo:", zoo);
        console.log("Oracle type:", oracleType);
        console.log("DodoOracle deployed at:", address(oracle));
    }
}
