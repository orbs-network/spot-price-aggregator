// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOracleSei, IOraclePrecompile} from "contracts/view/UsdOracleSei.sol";

contract UsdOracleSeiTest is Test {
    UsdOracleSei public oracleSei;

    address public aggregator;
    address public usdc;
    address public usdt;
    address public weth;
    address public wbtc;
    address public sei;
    address public wsei;

    function setUp() public {
        string memory json = vm.readFile("script/input/config.json");
        string memory chainKey = ".1329";
        address[] memory deployTokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".deploy.tokens"));
        string[] memory deployDenoms = vm.parseJsonStringArray(json, string.concat(chainKey, ".deploy.denoms"));
        aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));

        string memory rpcUrl = "https://sei-evm-rpc.publicnode.com";

        usdc = deployTokens[0];
        usdt = deployTokens[1];
        weth = deployTokens[2];
        wbtc = deployTokens[3];
        sei = deployTokens[4];
        wsei = deployTokens[5];

        vm.createSelectFork(rpcUrl);

        // Foundry (revm) doesn't implement Sei's custom oracle precompile at 0x1008. We fetch the real
        // precompile output via `vm.rpc(eth_call)` and mock the call locally for determinism.
        // Only map the base token (USDC) to force `usd(token)` to go through the offchain oracle path for other tokens.
        address[] memory tokens = new address[](1);
        string[] memory denoms = new string[](1);
        tokens[0] = usdc;
        denoms[0] = deployDenoms[0];

        oracleSei = new UsdOracleSei(aggregator, tokens, denoms);

        address oraclePrecompile = address(oracleSei.ORACLE_PRECOMPILE());
        bytes memory callData = abi.encodeWithSelector(IOraclePrecompile.getExchangeRates.selector);
        bytes memory rawRates = _fetchRates(oraclePrecompile, callData);
        vm.mockCall(oraclePrecompile, callData, rawRates);
    }

    function testUsd_usdc() public view {
        uint256 price = oracleSei.usd(usdc);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_usdt() public view {
        uint256 price = oracleSei.usd(usdt);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_weth() public view {
        uint256 price = oracleSei.usd(weth);
        assertGt(price, 100e18);
        assertLt(price, 100_000e18);
    }

    function testUsd_wbtc() public view {
        uint256 price = oracleSei.usd(wbtc);
        assertGt(price, 1000e18);
        assertLt(price, 10_000_000e18);
    }

    function testUsd_sei() public view {
        uint256 price = oracleSei.usd(sei);
        assertGt(price, 0.0001e18);
        assertLt(price, 100e18);
    }

    function testUsd_wsei() public view {
        uint256 price = oracleSei.usd(wsei);
        assertGt(price, 0.0001e18);
        assertLt(price, 100e18);
    }

    function _fetchRates(address precompile, bytes memory callData) internal returns (bytes memory raw) {
        string memory params =
            string.concat('[{"to":"', vm.toString(precompile), '","data":"', vm.toString(callData), '"},"latest"]');
        bytes memory resp = vm.rpc("eth_call", params);
        if (resp.length > 0 && resp[0] == bytes1("{")) {
            raw = vm.parseJsonBytes(string(resp), ".result");
        } else if (resp.length > 1 && resp[0] == bytes1("0") && resp[1] == bytes1("x")) {
            raw = vm.parseBytes(string(resp));
        } else {
            raw = resp;
        }
    }
}
