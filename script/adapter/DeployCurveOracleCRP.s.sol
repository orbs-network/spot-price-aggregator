// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreDeploy} from "script/CoreDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {CurveOracleCRP} from "contracts/oracles/CurveOracleCRP.sol";
import {ICurveProvider} from "contracts/interfaces/ICurveProvider.sol";

contract DeployCurveOracleCRP is CoreDeploy {
    function run() external returns (CurveOracleCRP oracle) {
        address provider = _adapterAddress("provider");
        uint256 maxPools = _adapterUint("maxpools");
        require(provider != address(0), "missing provider");
        require(maxPools != 0, "missing maxpools");

        vm.broadcast();
        oracle = new CurveOracleCRP(ICurveProvider(provider), maxPools);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
