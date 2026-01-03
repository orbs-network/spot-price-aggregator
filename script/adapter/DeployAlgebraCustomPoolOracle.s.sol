// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";

contract DeployAlgebraCustomPoolOracle is Script {
    function run() external returns (AlgebraCustomPoolOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);

        address poolDeployer =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.poolDeployer"));
        address customDeployer = vm.parseJsonAddress(
            json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.customDeployer")
        );
        bytes32 initcodeHash =
            vm.parseJsonBytes32(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.initcodehash"));
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new AlgebraCustomPoolOracle(poolDeployer, customDeployer, initcodeHash);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
