// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {IWrapper} from "contracts/interfaces/IWrapper.sol";

/// @notice Adds an existing wrapper (from config env.address) to MultiWrapper.
contract AddWrapperFromConfig is Script {
    function run() external returns (address wrapperAddr) {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = string.concat(".", vm.toString(block.chainid));
        uint256 index = vm.envUint("INDEX");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        OffchainOracle oc = OffchainOracle(aggregator);
        MultiWrapper mw = oc.multiWrapper();

        string memory addrKey = string.concat(chainKey, ".wrappers[", vm.toString(index), "].env.address");
        require(vm.keyExistsJson(json, addrKey), "wrapper env.address missing");
        wrapperAddr = vm.parseJsonAddress(json, addrKey);
        require(wrapperAddr != address(0), "wrapper env.address is zero");

        vm.startBroadcast();
        mw.addWrapper(IWrapper(wrapperAddr));
        vm.stopBroadcast();
    }
}
