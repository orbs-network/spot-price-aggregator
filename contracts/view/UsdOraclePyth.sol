// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {UsdOracleCore} from "./UsdOracleCore.sol";

/// @notice View-only USD oracle (1e18) using Pyth feeds or offchain conversion to a base token.
/// @dev Pricing flow: (1) direct USD feed when configured; otherwise (2) token -> base via OffchainOracle;
/// @dev then (3) base -> USD via the base Pyth feed.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOraclePyth is UsdOracleCore {
    using SafeCast for int256;

    error InvalidConstructorParams();
    error MissingFeed(address token);

    address public immutable pyth;
    mapping(address => bytes32) public feed;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param _pyth Pyth oracle contract address.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param feeds Pyth price IDs aligned 1:1 with tokens.
    constructor(address _aggregator, address _pyth, address[] memory tokens, bytes32[] memory feeds)
        UsdOracleCore(_aggregator, tokens[0])
    {
        if (_pyth == address(0) || tokens.length == 0 || tokens.length != feeds.length) {
            revert InvalidConstructorParams();
        }
        pyth = _pyth;
        for (uint256 i; i < tokens.length; i++) {
            feed[tokens[i]] = feeds[i];
        }
    }

    function _hasDirect(address token) internal view override returns (bool) {
        return feed[token] != bytes32(0);
    }

    function _directUsd(address token) internal view override returns (uint256 price, uint256 updated) {
        bytes32 id = feed[token];
        if (id == bytes32(0)) revert MissingFeed(token);

        (int64 rawPrice,, int32 exponent, uint256 publishTime) = IPythOracle(pyth).getPriceUnsafe(id);
        updated = publishTime;
        price = _scaleTo1e18(int256(rawPrice).toUint256(), exponent);
    }

    function _scaleTo1e18(uint256 rawPrice, int32 exponent) private pure returns (uint256) {
        int256 scaleExp = int256(18) + int256(exponent);
        if (scaleExp >= 0) {
            return rawPrice * (10 ** uint256(scaleExp));
        }
        return rawPrice / (10 ** uint256(-scaleExp));
    }
}

/// @notice Minimal Pyth oracle interface needed by this oracle.
interface IPythOracle {
    function getPriceUnsafe(bytes32 id)
        external
        view
        returns (int64 price, uint64 confidence, int32 exponent, uint256 updated);
}
