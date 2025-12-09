// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MooniswapOracle} from "contracts/oracles/MooniswapOracle.sol";
import {IMooniswapFactory} from "contracts/interfaces/IMooniswapFactory.sol";

contract DeployMooniswapOracle is Script {
    function run() external returns (MooniswapOracle oracle) {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address factory = vm.envAddress("FACTORY");
        uint256 oracleType = vm.envOr("TYPE", uint256(2)); // Mooniswap defaults to WETH_ETH

        vm.startBroadcast();
        oracle = new MooniswapOracle{salt: salt}(IMooniswapFactory(factory));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
