// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {DodoV2Oracle} from "contracts/oracles/DodoV2Oracle.sol";
import {IDVMFactory} from "contracts/interfaces/IDodoFactories.sol";

contract DeployDodoV2Oracle is Script {
    function run() external returns (DodoV2Oracle oracle) {
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address factory =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.factory"));
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new DodoV2Oracle{salt: salt}(IDVMFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
