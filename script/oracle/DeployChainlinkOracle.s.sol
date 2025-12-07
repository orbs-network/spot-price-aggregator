// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {ChainlinkOracle} from "contracts/oracles/ChainlinkOracle.sol";
import {IChainlink} from "contracts/interfaces/IChainlink.sol";

contract DeployChainlinkOracle is Script {
    function run() external {
        OffchainOracle oc = OffchainOracle(vm.envAddress("ORACLE"));
        bytes32 salt = vm.envOr("SALT", bytes32(0));
        address chainlink = vm.envAddress("CHAINLINK");
        uint256 oracleType = vm.envOr("TYPE", uint256(1)); // Chainlink defaults to ETH

        vm.startBroadcast();
        ChainlinkOracle oracle = new ChainlinkOracle{salt: salt}(IChainlink(chainlink));
        oc.addOracle(oracle, OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();

        console.log("OffchainOracle:", address(oc));
        console.log("Chainlink feed:", chainlink);
        console.log("Oracle type:", oracleType);
        console.log("ChainlinkOracle deployed at:", address(oracle));
    }
}
