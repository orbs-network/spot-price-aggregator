// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract DeployUsdOracle is Script {
    function run() external returns (UsdOracle oracle) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        string memory saltPath = string.concat(chainKey, ".salt");
        bytes32 salt;
        if (vm.keyExistsJson(json, saltPath)) {
            string memory saltStr = vm.parseJsonString(json, saltPath);
            if (bytes(saltStr).length != 0) {
                salt = vm.parseJsonBytes32(json, saltPath);
            }
        }
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        address[] memory tokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        address[] memory feeds = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.feeds"));
        require(feeds.length == tokens.length + 2, "feeds length must be tokens+2");
        address[] memory tokensWithBase = _prependNativeAndWrapped(tokens);

        vm.startBroadcast();
        console.logBytes32(hashInitCode(type(UsdOracle).creationCode, abi.encode(aggregator, tokensWithBase, feeds)));
        oracle = new UsdOracle{salt: salt}(aggregator, tokensWithBase, feeds);
        vm.stopBroadcast();
    }

    function _prependNativeAndWrapped(address[] memory tokens) private view returns (address[] memory tokensWithBase) {
        address weth = vm.envAddress("WETH");
        tokensWithBase = new address[](tokens.length + 2);
        tokensWithBase[0] = address(0);
        tokensWithBase[1] = weth;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokensWithBase[i + 2] = tokens[i];
        }
    }
}
