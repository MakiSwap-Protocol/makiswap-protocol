// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

// import 'maki-swap-periphery/contracts/interfaces/IWHT.sol';

interface IWHT {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
