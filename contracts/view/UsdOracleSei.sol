// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AggregatorLib} from "./AggregatorLib.sol";

/// @notice View-only USD oracle (1e18) for Sei using the oracle precompile or offchain conversion to a base token.
/// @dev Pricing flow: (1) Sei oracle precompile when denom is configured; otherwise (2) token -> base via
/// @dev OffchainOracle; then (3) base -> USD via the precompile.
/// @dev Intended for off-chain reads; not suitable for on-chain pricing.
contract UsdOracleSei {
    using AggregatorLib for address;

    error ArraysLengthMismatch();
    error MissingPrecompile(address token);

    address public immutable aggregator;
    address public immutable base;

    IOraclePrecompile public constant ORACLE_PRECOMPILE = IOraclePrecompile(0x0000000000000000000000000000000000001008);

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

    /// @notice Returns USD price from the Sei oracle precompile, scaled to 1e18.
    /// @param token Token with a configured denom.
    /// @return USD price scaled to 1e18.
    function usdFromPrecompile(address token) public view returns (uint256) {
        bytes32 target = denomHash[token];
        if (target == bytes32(0)) revert MissingPrecompile(token);

        IOraclePrecompile.DenomOracleExchangeRatePair[] memory rates = ORACLE_PRECOMPILE.getExchangeRates();
        for (uint256 i; i < rates.length; i++) {
            if (keccak256(bytes(rates[i].denom)) == target) {
                return parse1e18(rates[i].oracleExchangeRateVal.exchangeRate);
            }
        }
        revert MissingPrecompile(token);
    }

    /// @notice Parses a decimal string into a uint256 scaled to 1e18 (truncates beyond 18 decimals).
    /// @param rate Decimal string from the precompile (for example "1.2345").
    /// @return Parsed value scaled to 1e18.
    function parse1e18(string memory rate) public pure returns (uint256) {
        bytes memory b = bytes(rate);
        uint256 dot = b.length;
        for (uint256 i; i < b.length; i++) {
            if (b[i] == bytes1(".")) {
                dot = i;
                break;
            }
        }

        uint256 intPart = Strings.parseUint(rate, 0, dot);
        if (dot == b.length) return intPart * 1e18;

        uint256 fracStart = dot + 1;
        uint256 fracLen = b.length - fracStart;
        if (fracLen > 18) fracLen = 18;
        if (fracLen == 0) return intPart * 1e18;
        uint256 frac = Strings.parseUint(rate, fracStart, fracStart + fracLen);
        if (fracLen < 18) frac *= 10 ** (18 - fracLen);

        return intPart * 1e18 + frac;
    }
}

/// @notice Minimal Sei oracle precompile interface needed by this oracle.
interface IOraclePrecompile {
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
