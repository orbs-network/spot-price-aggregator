// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreDeploy} from "script/CoreDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SynthetixOracle} from "contracts/oracles/SynthetixOracle.sol";
import {ISynthetixProxy} from "contracts/interfaces/ISynthetixProxy.sol";

contract DeploySynthetixOracle is CoreDeploy {
    function run() external returns (SynthetixOracle oracle) {
        address proxy = _adapterAddress("proxy");
        require(proxy != address(0), "missing proxy");

        vm.broadcast();
        oracle = new SynthetixOracle(ISynthetixProxy(proxy));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.ETH);
    }
}
