// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SynthetixOracle} from "contracts/oracles/SynthetixOracle.sol";
import {ISynthetixProxy} from "contracts/interfaces/ISynthetixProxy.sol";

contract DeploySynthetixOracle is Script {
    function run() external returns (SynthetixOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address proxy =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.proxy"));
        uint256 oracleType = vm.envOr("TYPE", uint256(1)); // Synthetix uses native oracle style

        vm.startBroadcast();
        oracle = new SynthetixOracle(ISynthetixProxy(proxy));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
