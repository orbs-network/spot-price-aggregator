// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {KyberDmmOracle} from "contracts/oracles/KyberDmmOracle.sol";
import {IKyberDmmFactory} from "contracts/interfaces/IKyberDmmFactory.sol";

contract DeployKyberDmmOracle is Script {
    function run() external {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        KyberDmmOracle oracle = new KyberDmmOracle{salt: salt}(IKyberDmmFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();

        console.log("OffchainOracle:", address(oc));
        console.log("Kyber DMM factory:", factory);
        console.log("Oracle type:", oracleType);
        console.log("KyberDmmOracle deployed at:", address(oracle));
    }
}
