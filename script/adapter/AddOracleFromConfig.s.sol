// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";

/// @notice Adds an existing oracle (from config env.address) to OffchainOracle.
contract AddOracleFromConfig is Script {
    function run() external returns (address oracleAddr) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);

        string memory addrKey = string.concat(chainKey, ".adapters[", vm.toString(index), "].env.address");
        require(vm.keyExistsJson(json, addrKey), "adapter env.address missing");
        oracleAddr = vm.parseJsonAddress(json, addrKey);
        require(oracleAddr != address(0), "adapter env.address is zero");

        uint256 oracleType = vm.envOr("TYPE", uint256(0));

        vm.startBroadcast();
        oc.addOracle(IOracle(oracleAddr), OffchainOracle.OracleType(oracleType));
        vm.stopBroadcast();
    }
}
