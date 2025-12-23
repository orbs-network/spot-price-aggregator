// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {ChainlinkOracle} from "contracts/oracles/ChainlinkOracle.sol";
import {IChainlink} from "contracts/interfaces/IChainlink.sol";

contract DeployChainlinkOracle is Script {
    function run() external returns (ChainlinkOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address chainlink =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.chainlink"));
        uint256 oracleType = vm.envOr("TYPE", uint256(1)); // Chainlink defaults to ETH

        vm.startBroadcast();
        oracle = new ChainlinkOracle(IChainlink(chainlink));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
