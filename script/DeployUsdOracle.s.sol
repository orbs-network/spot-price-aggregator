// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract DeployUsdOracle is Script {
    function run() external returns (UsdOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        bytes32 salt = _parseJsonBytes32OrZero(json, string.concat(chainKey, ".salt"));
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        uint256 ttl = vm.parseJsonUint(json, string.concat(chainKey, ".env.ttl"));
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        address[] memory feeds = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.feeds"));

        vm.startBroadcast();
        console.logBytes32(hashInitCode(type(UsdOracle).creationCode, abi.encode(aggregator, ttl, tokens, feeds)));
        oracle = new UsdOracle{salt: salt}(aggregator, ttl, tokens, feeds);
        vm.stopBroadcast();
    }

    function _parseJsonBytes32OrZero(string memory json, string memory key) private view returns (bytes32 value) {
        if (!vm.keyExistsJson(json, key)) return bytes32(0);
        try vm.parseJsonBytes32(json, key) returns (bytes32 parsed) {
            return parsed;
        } catch {
            return bytes32(0);
        }
    }
}
