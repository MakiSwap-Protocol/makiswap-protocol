// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}