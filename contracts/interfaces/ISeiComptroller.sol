// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ICToken.sol";

/// @notice Minimal comptroller interface used on Sei where `markets` returns two fields.
interface ISeiComptroller {
    function getAllMarkets() external view returns (ICToken[] memory);

    function markets(ICToken market) external view returns (bool isListed, uint256 collateralFactorMantissa);
}
