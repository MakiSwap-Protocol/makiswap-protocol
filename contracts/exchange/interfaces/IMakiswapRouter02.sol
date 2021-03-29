// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

// import 'maki-swap-periphery/contracts/IMakiswapRouter02.sol';
import './IMakiswapRouter01.sol';

interface IMakiswapRouter02 is IMakiswapRouter01 {
    function removeLiquidityHTSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountHTMin,
        address to,
        uint deadline
    ) external returns (uint amountHT);
    function removeLiquidityHTWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountHTMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountHT);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactHTForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForHTSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
