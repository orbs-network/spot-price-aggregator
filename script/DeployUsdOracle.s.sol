// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract DeployUsdOracle is Script {
    function run() external returns (UsdOracle oracleUsd) {
        string memory json = vm.readFile("script/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));

        address oracle = vm.parseJsonAddress(json, string.concat(chainKey, ".oracle"));
        uint256 feedTtl = vm.parseJsonUint(json, string.concat(chainKey, ".usdOracle.feedTtl"));
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".usdOracle.tokens"));
        address[] memory feeds = vm.parseJsonAddressArray(json, string.concat(chainKey, ".usdOracle.feeds"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));

        vm.startBroadcast();
        console.logBytes32(hashInitCode(type(UsdOracle).creationCode, abi.encode(oracle, feedTtl, tokens, feeds)));
        oracleUsd = new UsdOracle{salt: salt}(oracle, feedTtl, tokens, feeds);
        vm.stopBroadcast();
    }
}
