// SPDX-License-Identifier: MIT
import 'maki-swap-lib/contracts/token/HRC20/IHRC20.sol';

pragma solidity 0.6.12;

interface IMigratorChef {
    // Perform LP token migration from legacy MakiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to MakiSwap LP tokens.
    // MakiSwap must mint EXACTLY the same amount of Maki LP tokens or
    // else something bad will happen. Traditional MakiSwap does not
    // do that so be careful!
    function migrate(IHRC20 token) external returns (IHRC20);
}