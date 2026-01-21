// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {RpcUtils} from "test/utils/RpcUtils.sol";
import {UsdOracleSei, ISeiPrecompile} from "contracts/view/UsdOracleSei.sol";

contract UsdOracleSeiTest is RpcUtils {
    UsdOracleSei public oracleSei;

    address private constant WBASE = 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7;

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
        address[] memory deployTokens = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.tokens"));
        string[] memory deployDenoms = vm.parseJsonStringArray(json, string.concat(chainKey, ".env.denoms"));
        aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        require(deployTokens.length >= 4, "tokens length < 4");
        require(deployDenoms.length == deployTokens.length + 2, "denoms length must be tokens+2");

        address[] memory tokens = new address[](deployTokens.length + 2);
        string[] memory denoms = deployDenoms;
        tokens[0] = address(0);
        tokens[1] = WBASE;
        for (uint256 i = 0; i < deployTokens.length; i++) {
            tokens[i + 2] = deployTokens[i];
        }

        sei = tokens[0];
        wsei = tokens[1];
        usdc = tokens[2];
        usdt = tokens[3];
        weth = tokens[4];
        wbtc = tokens[5];

        vm.createSelectFork(_rpcUrl("sei"));

        // Foundry (revm) doesn't implement Sei's custom oracle precompile at 0x1008. We fetch the real
        // precompile output via `vm.rpc(eth_call)` and mock the call locally for determinism.
        // Only map the base token (USDC) to force `usd(token)` to go through the offchain oracle path for other tokens.
        address[] memory baseTokens = new address[](1);
        string[] memory baseDenoms = new string[](1);
        baseTokens[0] = usdc;
        baseDenoms[0] = denoms[2];

        oracleSei = new UsdOracleSei(aggregator, baseTokens, baseDenoms);

        address seiPrecompile = address(oracleSei.SEI_PRECOMPILE());
        bytes memory callData = abi.encodeWithSelector(ISeiPrecompile.getExchangeRates.selector);
        bytes memory rawRates = _fetchRates(seiPrecompile, callData);
        vm.mockCall(seiPrecompile, callData, rawRates);
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

    function testUsd_batch() public view {
        address[] memory tokens = new address[](3);
        tokens[0] = usdc;
        tokens[1] = usdt;
        tokens[2] = wbtc;

        uint256[] memory prices = oracleSei.usd(tokens);
        assertEq(prices.length, 3);

        assertGt(prices[0], 0.9e18);
        assertLt(prices[0], 1.1e18);
        assertGt(prices[1], 0.9e18);
        assertLt(prices[1], 1.1e18);
        assertGt(prices[2], 1000e18);
        assertLt(prices[2], 10_000_000e18);
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
