// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MooniswapOracle} from "contracts/oracles/MooniswapOracle.sol";
import {IMooniswapFactory} from "contracts/interfaces/IMooniswapFactory.sol";

contract DeployMooniswapOracle is Script {
    function run() external returns (MooniswapOracle oracle) {
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address factory =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.factory"));
        uint256 oracleType = vm.envOr("TYPE", uint256(2)); // Mooniswap defaults to WETH_ETH

        vm.startBroadcast();
        oracle = new MooniswapOracle{salt: salt}(IMooniswapFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
