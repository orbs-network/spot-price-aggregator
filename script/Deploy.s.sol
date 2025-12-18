// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";
import {IWrapper} from "contracts/interfaces/IWrapper.sol";
import {BaseCoinWrapper} from "contracts/wrappers/BaseCoinWrapper.sol";

contract Deploy is Script {
    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    IERC20 private constant _NATIVE = IERC20(0x0000000000000000000000000000000000000000);

    function run()
        external
        returns (BaseCoinWrapper baseCoinWrapper, MultiWrapper multiWrapper, OffchainOracle oracle)
    {
        address owner = vm.envAddress("OWNER");
        address weth = vm.envAddress("WETH");
        bytes32 salt = vm.envOr("SALT", bytes32(0));

        IERC20[] memory connectors = _appendConnectors(vm.envAddress("CONNECTORS", ","), IERC20(weth));

        vm.startBroadcast();

        // Deploy base WETH wrapper and seed MultiWrapper with it
        baseCoinWrapper = new BaseCoinWrapper{salt: salt}(_NATIVE, IERC20(weth));
        IWrapper[] memory initialWrappers = new IWrapper[](1);
        initialWrappers[0] = baseCoinWrapper;
        multiWrapper = new MultiWrapper{salt: salt}(initialWrappers, owner);

        // Deploy offchain oracle (empty oracles; add later with dedicated scripts)
        IOracle[] memory emptyOracles = new IOracle[](0);
        OffchainOracle.OracleType[] memory emptyTypes = new OffchainOracle.OracleType[](0);
        oracle = new OffchainOracle{salt: salt}(multiWrapper, emptyOracles, emptyTypes, connectors, IERC20(weth), owner);

        vm.stopBroadcast();
    }

    // ------- Internals -------
    function _appendConnectors(address[] memory envConnectors, IERC20 wNative)
        private
        pure
        returns (IERC20[] memory connectors)
    {
        connectors = new IERC20[](envConnectors.length + 3);
        connectors[0] = _NONE;
        connectors[1] = _NATIVE;
        connectors[2] = wNative;
        for (uint256 i = 0; i < envConnectors.length; i++) {
            connectors[i + 3] = IERC20(envConnectors[i]);
        }
    }
}
