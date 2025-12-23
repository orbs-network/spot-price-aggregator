// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {KyberDmmOracle} from "contracts/oracles/KyberDmmOracle.sol";
import {IKyberDmmFactory} from "contracts/interfaces/IKyberDmmFactory.sol";

contract DeployKyberDmmOracle is Script {
    function run() external returns (KyberDmmOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address factory =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.factory"));
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new KyberDmmOracle(IKyberDmmFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
