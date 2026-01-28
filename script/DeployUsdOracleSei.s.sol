// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreDeploy} from "script/CoreDeploy.s.sol";
import {UsdOracleSei} from "contracts/view/UsdOracleSei.sol";

contract DeployUsdOracleSei is CoreDeploy {
    function run() external returns (UsdOracleSei oracle) {
        address[] memory tokens = _tokens();
        string[] memory denoms = _envStringArray("denoms");

        _logCreate2(type(UsdOracleSei).creationCode, abi.encode(cfg.aggregator, tokens, denoms));
        vm.broadcast();
        oracle = new UsdOracleSei{salt: cfg.salt}(cfg.aggregator, tokens, denoms);
    }
}
