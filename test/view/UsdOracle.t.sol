// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOracle, IChainlinkAggregatorV3} from "contracts/view/UsdOracle.sol";
import {IOffchainOracleAggregator} from "contracts/view/AggregatorLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UsdOracleTest is Test {
    UsdOracle public oracleUsd;
    MockOffchainOracleAggregator public offchainOracle;
    MockAggregatorV3 public ethUsdFeed;

    function setUp() public {
        offchainOracle = new MockOffchainOracleAggregator();
        ethUsdFeed = new MockAggregatorV3();

        // 3000 USD/ETH with 8 decimals
        ethUsdFeed.setDecimals(8);
        ethUsdFeed.setAnswer(3000e8, block.timestamp);

        address[] memory tokens = new address[](1);
        address[] memory feeds = new address[](1);
        tokens[0] = address(0); // ETH as base
        feeds[0] = address(ethUsdFeed);

        oracleUsd = new UsdOracle(address(offchainOracle), 1 days, tokens, feeds);
    }

    function testEthUsd_scalesTo1e18() public view {
        assertEq(oracleUsd.usdFromFeed(address(0)), 3000e18);
    }

    function testUsd_convertsTokenToUsd() public {
        MockToken token = new MockToken(6);

        // rateToEth = ETH_atomic / token_atomic * 1e18
        // If 1 token (1e6) == 0.0005 ETH (5e14 wei):
        //   rateToEth = (5e14 / 1e6) * 1e18 = 5e26
        offchainOracle.setRateToEth(5e26);

        uint256 usdPerToken = oracleUsd.usd(address(token));
        assertEq(usdPerToken, 1.5e18); // 0.0005 ETH * 3000 USD/ETH = 1.5 USD
    }

    function testEthUsd_revertsOnStaleAnswer() public {
        ethUsdFeed.setAnswer(3000e8, block.timestamp);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(UsdOracle.StaleFeedAnswer.selector);
        oracleUsd.usdFromFeed(address(0));
    }
}

contract MockOffchainOracleAggregator is IOffchainOracleAggregator {
    uint256 public rateToEth;

    function setRateToEth(uint256 _rateToEth) external {
        rateToEth = _rateToEth;
    }

    function getRateWithThreshold(IERC20, IERC20, bool, uint256) external view returns (uint256 weightedRate) {
        return rateToEth;
    }
}

contract MockAggregatorV3 is IChainlinkAggregatorV3 {
    uint8 public override decimals;
    int256 public answer;
    uint256 public updatedAt;

    function setDecimals(uint8 d) external {
        decimals = d;
    }

    function setAnswer(int256 a, uint256 t) external {
        answer = a;
        updatedAt = t;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 _answer, uint256 startedAt, uint256 _updatedAt, uint80 answeredInRound)
    {
        return (1, answer, updatedAt, updatedAt, 1);
    }
}

    contract MockToken {
        uint8 private immutable _decimals;

        constructor(uint8 d) {
            _decimals = d;
        }

        function decimals() external view returns (uint8) {
            return _decimals;
        }
    }
