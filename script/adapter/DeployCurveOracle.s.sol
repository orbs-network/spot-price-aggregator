// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {CurveOracle} from "contracts/oracles/CurveOracle.sol";
import {ICurveProvider} from "contracts/interfaces/ICurveProvider.sol";

contract DeployCurveOracle is Script {
    function run() external returns (CurveOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address provider =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.provider"));
        uint256 maxPools =
            vm.parseJsonUint(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.maxpools"));
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // Curve treated as WETH by default

        vm.startBroadcast();
        oracle = new CurveOracle(ICurveProvider(provider), maxPools);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
