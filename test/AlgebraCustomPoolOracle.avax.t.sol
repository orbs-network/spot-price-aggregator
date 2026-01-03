// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AlgebraOracle} from "contracts/oracles/AlgebraOracle.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";

contract AlgebraCustomPoolOracleAvaxTest is Test {
    IERC20 private constant NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    string private constant AVAX_RPC = "https://avalanche-c-chain-rpc.publicnode.com";
    string private constant CONFIG_PATH = "script/input/config.json";
    string private constant CHAIN_KEY = ".43114";

    address private poolDeployer;
    address private cl50Deployer;
    bytes32 private initcodeHash;
    IERC20 private wavax;
    IERC20 private usdc;

    function setUp() public {
        vm.createSelectFork(AVAX_RPC);

        string memory json = vm.readFile(CONFIG_PATH);
        poolDeployer = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[7].env.poolDeployer"));
        cl50Deployer = vm.parseJsonAddress(json, string.concat(CHAIN_KEY, ".adapters[9].env.customDeployer"));
        initcodeHash = vm.parseJsonBytes32(json, string.concat(CHAIN_KEY, ".adapters[7].env.initcodehash"));

        address[] memory connectors = vm.parseJsonAddressArray(json, string.concat(CHAIN_KEY, ".connectors"));
        require(connectors.length >= 5, "connectors length < 5");
        usdc = IERC20(connectors[4]);
        wavax = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    }

    function test_blackholeClCustomPoolOracle_resolvesWavaxUsdc() public {
        AlgebraCustomPoolOracle fixedOracle = new AlgebraCustomPoolOracle(poolDeployer, cl50Deployer, initcodeHash);
        (uint256 fixedRate, uint256 fixedWeight) = fixedOracle.getRate(wavax, usdc, NONE, 0);
        assertGt(fixedRate, 0, "fixed rate=0");
        assertGt(fixedWeight, 0, "fixed weight=0");

        // Prior AlgebraOracle config (factory = custom deployer) does not resolve pools.
        AlgebraOracle oldOracle = new AlgebraOracle(cl50Deployer, initcodeHash);
        (uint256 oldRate, uint256 oldWeight) = oldOracle.getRate(wavax, usdc, NONE, 0);
        assertEq(oldRate, 0, "old rate should be 0");
        assertEq(oldWeight, 0, "old weight should be 0");
    }
}
