// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOraclePyth} from "contracts/view/UsdOraclePyth.sol";
import {UsdOracleCore} from "contracts/view/UsdOracleCore.sol";
import {MockOffchainOracleAggregator, MockPythOracle, MockToken} from "test/utils/UsdOracleMocks.sol";

contract UsdOraclePythTest is Test {
    UsdOraclePyth public oracleUsd;
    MockOffchainOracleAggregator public offchainOracle;
    MockPythOracle public pythOracle;
    bytes32 public constant ETH_USD_PRICE_ID = bytes32(uint256(1));

    function setUp() public {
        offchainOracle = new MockOffchainOracleAggregator();
        pythOracle = new MockPythOracle();

        // 3000 USD/ETH with exponent -8
        pythOracle.setPrice(ETH_USD_PRICE_ID, 3000e8, 0, -8, block.timestamp);

        address[] memory tokens = new address[](1);
        bytes32[] memory feeds = new bytes32[](1);
        tokens[0] = address(0); // ETH as base
        feeds[0] = ETH_USD_PRICE_ID;

        oracleUsd = new UsdOraclePyth(address(offchainOracle), address(pythOracle), tokens, feeds);
    }

    function testEthUsd_scalesTo1e18() public view {
        (uint256 price, uint8 decimals) = oracleUsd.usd(address(0));
        assertEq(price, 3000e18);
        assertEq(decimals, 18);
    }

    function testUsd_usesAggregatorWhenFeedIsZero() public {
        MockToken token = new MockToken(6);
        offchainOracle.setRateToEth(5e26);

        address[] memory tokens = new address[](2);
        bytes32[] memory feeds = new bytes32[](2);
        tokens[0] = address(0);
        tokens[1] = address(token);
        feeds[0] = ETH_USD_PRICE_ID;
        feeds[1] = bytes32(0);

        oracleUsd = new UsdOraclePyth(address(offchainOracle), address(pythOracle), tokens, feeds);

        (uint256 usdPerToken,) = oracleUsd.usd(address(token));
        assertEq(usdPerToken, 1.5e18);
    }

    function testEthUsd_revertsOnStaleAnswer() public {
        pythOracle.setPrice(ETH_USD_PRICE_ID, 3000e8, 0, -8, block.timestamp);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(abi.encodeWithSelector(UsdOracleCore.StaleAnswer.selector, address(0)));
        oracleUsd.usd(address(0));
    }
}
