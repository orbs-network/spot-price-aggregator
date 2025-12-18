// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapOracle} from "contracts/oracles/UniswapOracle.sol";
import {IUniswapFactory} from "contracts/interfaces/IUniswapFactory.sol";

contract DeployUniswapOracle is Script {
    function run() external returns (UniswapOracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        uint256 oracleType = vm.envOr("TYPE", uint256(1)); // Router oracle defaults to ETH

        vm.startBroadcast();
        oracle = new UniswapOracle{salt: salt}(IUniswapFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
