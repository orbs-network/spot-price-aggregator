// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {UsdOracleSei} from "contracts/view/UsdOracleSei.sol";

contract DeployUsdOracleSei is Script {
    function run() external returns (UsdOracleSei oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        bytes32 salt = _parseJsonBytes32OrZero(json, string.concat(chainKey, ".salt"));
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        string[] memory denoms = vm.parseJsonStringArray(json, string.concat(chainKey, ".env.denoms"));

        vm.startBroadcast();
        console.logBytes32(hashInitCode(type(UsdOracleSei).creationCode, abi.encode(aggregator, tokens, denoms)));
        oracle = new UsdOracleSei{salt: salt}(aggregator, tokens, denoms);
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
