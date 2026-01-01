// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {UsdOracleSei} from "contracts/view/UsdOracleSei.sol";

contract DeployUsdOracleSei is Script {
    function run() external returns (UsdOracleSei oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        bytes32 salt = vm.parseJsonBytes32(json, string.concat(chainKey, ".salt"));
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        string[] memory denoms = vm.parseJsonStringArray(json, string.concat(chainKey, ".env.denoms"));
        require(denoms.length == tokens.length + 2, "denoms length must be tokens+2");
        address[] memory tokensWithBase = _prependNativeAndWrapped(tokens);

        vm.startBroadcast();
        console.logBytes32(
            hashInitCode(type(UsdOracleSei).creationCode, abi.encode(aggregator, tokensWithBase, denoms))
        );
        oracle = new UsdOracleSei{salt: salt}(aggregator, tokensWithBase, denoms);
        vm.stopBroadcast();
    }

    function _prependNativeAndWrapped(address[] memory tokens) private view returns (address[] memory tokensWithBase) {
        address weth = vm.envAddress("WETH");
        tokensWithBase = new address[](tokens.length + 2);
        tokensWithBase[0] = address(0);
        tokensWithBase[1] = weth;
        for (uint256 i; i < tokens.length; i++) {
            tokensWithBase[i + 2] = tokens[i];
        }
    }
}
