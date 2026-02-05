// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {UsdOracleCore} from "./UsdOracleCore.sol";

/// @notice View-only USD oracle (1e18) using Flare FTSO v2 feeds or offchain conversion to a base token.
/// @dev Pricing flow: (1) direct USD feed when configured; otherwise (2) token -> base via OffchainOracle;
/// @dev then (3) base -> USD via the base FTSO v2 feed.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracleFlare is UsdOracleCore {
    error InvalidConstructorParams();
    error MissingFeed(address token);

    address public constant FTSO_V2 = 0x7BDE3Df0624114eDB3A67dFe6753e62f4e7c1d20;

    mapping(address => bytes21) public feed;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param ftsos FTSO v2 feed IDs aligned 1:1 with tokens.
    constructor(address _aggregator, address[] memory tokens, bytes32[] memory ftsos)
        UsdOracleCore(_aggregator, tokens[0])
    {
        if (tokens.length == 0 || tokens.length != ftsos.length) {
            revert InvalidConstructorParams();
        }
        for (uint256 i; i < tokens.length; i++) {
            feed[tokens[i]] = bytes21(ftsos[i]);
        }
    }

    function _hasDirect(address token) internal view override returns (bool) {
        return feed[token] != bytes21(0);
    }

    function _directUsd(address token) internal view override returns (uint256 price, uint256 updated) {
        bytes21 id = feed[token];
        if (id == bytes21(0)) revert MissingFeed(token);

        (uint256 value, int8 decimals, uint64 timestamp) = IFtsoV2(FTSO_V2).getFeedById(id);
        updated = uint256(timestamp);
        price = _scaleTo1e18(value, decimals);
    }

    function _scaleTo1e18(uint256 value, int8 decimals) private pure returns (uint256) {
        int256 scaleExp = int256(18) - int256(decimals);
        if (scaleExp >= 0) {
            return value * (10 ** uint256(scaleExp));
        }
        return value / (10 ** uint256(-scaleExp));
    }
}

/// @notice Minimal FTSO v2 interface needed by this oracle.
interface IFtsoV2 {
    function getFeedById(bytes21 id) external view returns (uint256 value, int8 decimals, uint64 timestamp);
}
