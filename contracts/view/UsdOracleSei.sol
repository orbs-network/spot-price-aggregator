// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {AggregatorLib} from "./AggregatorLib.sol";
import {ParseLib} from "./ParseLib.sol";

/// @notice View-only USD oracle (1e18) for Sei using the Sei precompile or offchain conversion to a base token.
/// @dev Pricing flow: (1) Sei precompile when denom is configured; otherwise (2) token -> base via
/// @dev OffchainOracle; then (3) base -> USD via the precompile.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracleSei {
    using AggregatorLib for address;

    error ArraysLengthMismatch();
    error MissingPrecompile(address token);

    address public immutable aggregator;
    address public immutable base;

    ISeiPrecompile public constant SEI_PRECOMPILE = ISeiPrecompile(0x0000000000000000000000000000000000001008);

    mapping(address => bytes32) public denomHash;

    /// @param _aggregator Offchain oracle used for token -> base conversion.
    /// @param tokens Token list; tokens[0] is the base token.
    /// @param denoms Sei denom strings aligned 1:1 with tokens.
    constructor(address _aggregator, address[] memory tokens, string[] memory denoms) {
        aggregator = _aggregator;

        if (tokens.length == 0 || tokens.length != denoms.length) revert ArraysLengthMismatch();
        base = tokens[0];
        for (uint256 i; i < tokens.length; i++) {
            denomHash[tokens[i]] = keccak256(bytes(denoms[i]));
        }
    }

    /// @notice Returns token/USD price scaled to 1e18.
    /// @param token Token to price.
    /// @return USD price scaled to 1e18.
    function usd(address token) public view returns (uint256) {
        if (denomHash[token] != bytes32(0)) return usdFromPrecompile(token);
        return aggregator.usdFromBase(token, base, usdFromPrecompile(base));
    }

    /// @notice Returns token/USD prices scaled to 1e18.
    /// @param tokens Tokens to price.
    /// @return prices USD prices scaled to 1e18.
    function usd(address[] memory tokens) public view returns (uint256[] memory prices) {
        prices = new uint256[](tokens.length);
        uint256 baseUsd = usdFromPrecompile(base);

        for (uint256 i; i < tokens.length; i++) {
            if (denomHash[tokens[i]] != bytes32(0)) {
                prices[i] = usdFromPrecompile(tokens[i]);
            } else {
                prices[i] = aggregator.usdFromBase(tokens[i], base, baseUsd);
            }
        }
    }

    /// @notice Returns USD price from the Sei precompile, scaled to 1e18.
    /// @param token Token with a configured denom.
    /// @return USD price scaled to 1e18.
    function usdFromPrecompile(address token) public view returns (uint256) {
        bytes32 target = denomHash[token];
        if (target == bytes32(0)) revert MissingPrecompile(token);

        ISeiPrecompile.DenomOracleExchangeRatePair[] memory rates = SEI_PRECOMPILE.getExchangeRates();
        for (uint256 i; i < rates.length; i++) {
            if (keccak256(bytes(rates[i].denom)) == target) {
                return ParseLib.parse1e18(rates[i].oracleExchangeRateVal.exchangeRate);
            }
        }
        revert MissingPrecompile(token);
    }
}

/// @notice Minimal Sei precompile interface needed by this oracle.
interface ISeiPrecompile {
    struct OracleExchangeRate {
        string exchangeRate;
        string lastUpdate;
        int64 lastUpdateTimestamp;
    }

    struct DenomOracleExchangeRatePair {
        string denom;
        OracleExchangeRate oracleExchangeRateVal;
    }

    function getExchangeRates() external view returns (DenomOracleExchangeRatePair[] memory rates);
}
