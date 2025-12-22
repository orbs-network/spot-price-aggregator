// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AggregatorLib} from "./AggregatorLib.sol";

/// @notice View-only USD oracle (1e18) using direct feeds or offchain conversion to a base token.
/// @dev Pricing flow: (1) direct USD feed when configured; otherwise (2) token -> base via OffchainOracle;
/// @dev then (3) base -> USD via the base feed.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracle {
    using SafeCast for int256;
    using AggregatorLib for address;

    error ArraysLengthMismatch();
    error MissingFeed(address token);
    error InvalidFeedAnswer();
    error StaleFeedAnswer();

    address public immutable aggregator;
    address public immutable base;
    uint256 public immutable feedTtl;

    mapping(address => address) public usdFeed;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param _feedTtl Max age for feed answers before they are treated as stale.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param feeds Chainlink feed addresses, aligned 1:1 with tokens.
    constructor(address _aggregator, uint256 _feedTtl, address[] memory tokens, address[] memory feeds) {
        aggregator = _aggregator;
        feedTtl = _feedTtl;

        if (tokens.length == 0 || tokens.length != feeds.length) revert ArraysLengthMismatch();
        base = tokens[0];
        for (uint256 i; i < tokens.length; i++) {
            usdFeed[tokens[i]] = feeds[i];
        }
    }

    /// @notice Returns token/USD price scaled to 1e18.
    /// @param token Token to price.
    /// @return USD price scaled to 1e18.
    function usd(address token) public view returns (uint256) {
        if (usdFeed[token] != address(0)) return usdFromFeed(token);
        return aggregator.usdFromBase(token, base, usdFromFeed(base));
    }

    /// @notice Returns USD price from a configured feed, scaled to 1e18.
    /// @param token Token with a configured feed.
    /// @return USD price scaled to 1e18.
    function usdFromFeed(address token) public view returns (uint256) {
        address feed = usdFeed[token];
        if (feed == address(0)) revert MissingFeed(token);

        (, int256 answer,, uint256 updatedAt,) = IChainlinkAggregatorV3(feed).latestRoundData();
        if (answer <= 0) revert InvalidFeedAnswer();
        if (block.timestamp >= updatedAt + feedTtl) revert StaleFeedAnswer();

        uint256 price = answer.toUint256();
        uint8 d = IChainlinkAggregatorV3(feed).decimals();
        if (d == 18) return price;
        if (d < 18) return price * (10 ** (18 - d));
        return price / (10 ** (d - 18));
    }
}

/// @notice Minimal Chainlink aggregator interface needed by this oracle.
interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
