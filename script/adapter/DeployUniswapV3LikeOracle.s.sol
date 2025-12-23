// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapV3LikeOracle} from "contracts/oracles/UniswapV3LikeOracle.sol";

contract DeployUniswapV3LikeOracle is Script {
    function run() external returns (UniswapV3LikeOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        address factory =
            vm.parseJsonAddress(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.factory"));
        bytes32 initcodeHash =
            vm.parseJsonBytes32(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.initcodehash"));
        uint256[] memory feesRaw =
            vm.parseJsonUintArray(json, string.concat(chainKey, ".adapters[", vm.toString(index), "].env.fees"));
        uint24[] memory fees = _toUint24(feesRaw);
        uint256 oracleType = vm.envOr("TYPE", uint256(0)); // AMM defaults to WETH

        vm.startBroadcast();
        oracle = new UniswapV3LikeOracle(factory, initcodeHash, fees);
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }

    function _toUint24(uint256[] memory src) private pure returns (uint24[] memory dst) {
        dst = new uint24[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = uint24(src[i]);
        }
    }
}
