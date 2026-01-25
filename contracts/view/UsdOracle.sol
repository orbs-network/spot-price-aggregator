// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {UsdOracleCore} from "./UsdOracleCore.sol";

/// @notice View-only USD oracle (1e18) using direct feeds or offchain conversion to a base token.
/// @dev Pricing flow: (1) direct USD feed when configured; otherwise (2) token -> base via OffchainOracle;
/// @dev then (3) base -> USD via the base feed.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracle is UsdOracleCore {
    using SafeCast for int256;

    error ArraysLengthMismatch();
    error MissingFeed(address token);

    mapping(address => address) public usdFeed;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param feeds Chainlink feed addresses, aligned 1:1 with tokens.
    constructor(address _aggregator, address[] memory tokens, address[] memory feeds)
        UsdOracleCore(_aggregator, tokens[0])
    {
        if (tokens.length == 0 || tokens.length != feeds.length) revert ArraysLengthMismatch();
        for (uint256 i; i < tokens.length; i++) {
            usdFeed[tokens[i]] = feeds[i];
        }
    }

    function _hasDirect(address token) internal view override returns (bool) {
        return usdFeed[token] != address(0);
    }

    function _directUsd(address token) internal view override returns (uint256 price, uint256 updated) {
        address feed = usdFeed[token];
        if (feed == address(0)) revert MissingFeed(token);

        (, int256 answer,, uint256 feedUpdated,) = IChainlinkAggregatorV3(feed).latestRoundData();
        updated = feedUpdated;

        uint256 rawPrice = answer.toUint256();
        uint8 d = IChainlinkAggregatorV3(feed).decimals();
        if (d == 18) price = rawPrice;
        else if (d < 18) price = rawPrice * (10 ** (18 - d));
        else price = rawPrice / (10 ** (d - 18));
    }
}

/// @notice Minimal Chainlink aggregator interface needed by this oracle.
interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updated, uint80 answeredInRound);
}
