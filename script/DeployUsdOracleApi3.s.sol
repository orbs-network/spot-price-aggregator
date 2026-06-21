// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {UsdOracleApi3} from "contracts/view/UsdOracleApi3.sol";

contract DeployUsdOracleApi3 is ConfigDeploy {
    function run() external returns (UsdOracleApi3 oracle) {
        address[] memory tokens = _tokens();
        address[] memory feeds = _envAddressArray("api3s");

        _logCreate2(type(UsdOracleApi3).creationCode, abi.encode(cfg.aggregator, tokens, feeds));
        vm.broadcast();
        oracle = new UsdOracleApi3{salt: cfg.salt}(cfg.aggregator, tokens, feeds);
    }
}
