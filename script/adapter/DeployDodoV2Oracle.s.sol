// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreDeploy} from "script/CoreDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {DodoV2Oracle} from "contracts/oracles/DodoV2Oracle.sol";
import {IDVMFactory} from "contracts/interfaces/IDodoFactories.sol";

contract DeployDodoV2Oracle is CoreDeploy {
    function run() external returns (DodoV2Oracle oracle) {
        address factory = _adapterAddress("factory");
        require(factory != address(0), "missing factory");

        vm.broadcast();
        oracle = new DodoV2Oracle(IDVMFactory(factory));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
