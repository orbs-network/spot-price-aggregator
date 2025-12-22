// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {UsdOracleSei} from "contracts/view/UsdOracleSei.sol";

contract DeployUsdOracleSei is Script {
    function run() external returns (UsdOracleSei oracleSei) {
        string memory json = vm.readFile("script/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));

        address oracle = vm.parseJsonAddress(json, string.concat(chainKey, ".oracle"));
        bytes32 salt = vm.envOr("SALT", bytes32(0x374eb1cf3455289c1707dd0eabb21e6b757f37a905b2437f3b549bbbbe16c433));

        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".usdOracleSei.tokens"));
        string[] memory denoms = vm.parseJsonStringArray(json, string.concat(chainKey, ".usdOracleSei.denoms"));

        vm.startBroadcast();
        console.logBytes32(hashInitCode(type(UsdOracleSei).creationCode, abi.encode(oracle, tokens, denoms)));
        oracleSei = new UsdOracleSei{salt: salt}(oracle, tokens, denoms);
        vm.stopBroadcast();
    }
}
