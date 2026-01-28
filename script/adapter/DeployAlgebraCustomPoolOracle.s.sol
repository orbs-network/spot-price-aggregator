// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreDeploy} from "script/CoreDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";

contract DeployAlgebraCustomPoolOracle is CoreDeploy {
    function run() external returns (AlgebraCustomPoolOracle oracle) {
        address poolDeployer = _adapterAddress("poolDeployer");
        address customDeployer = _adapterAddress("customDeployer");
        bytes32 initcodehash = _adapterBytes32("initcodehash");
        require(poolDeployer != address(0), "missing poolDeployer");
        require(customDeployer != address(0), "missing customDeployer");
        require(initcodehash != bytes32(0), "missing initcodehash");

        vm.broadcast();
        oracle = new AlgebraCustomPoolOracle(poolDeployer, customDeployer, initcodehash);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
