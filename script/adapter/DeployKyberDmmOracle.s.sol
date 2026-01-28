// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreDeploy} from "script/CoreDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {KyberDmmOracle} from "contracts/oracles/KyberDmmOracle.sol";
import {IKyberDmmFactory} from "contracts/interfaces/IKyberDmmFactory.sol";

contract DeployKyberDmmOracle is CoreDeploy {
    function run() external returns (KyberDmmOracle oracle) {
        address factory = _adapterAddress("factory");
        require(factory != address(0), "missing factory");

        vm.broadcast();
        oracle = new KyberDmmOracle(IKyberDmmFactory(factory));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
