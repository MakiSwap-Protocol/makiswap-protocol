// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import 'makiswap-core/contracts/interfaces/IMakiswapFactory.sol';
import 'makiswap-core/contracts/MakiswapPair.sol';
import 'makiswap-core/contracts/MakiswapHRC20.sol';

contract MakiswapFactory is IMakiswapFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(MakiswapPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Makiswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Makiswap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Makiswap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(MakiswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        MakiswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'Makiswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external {
        require(msg.sender == feeToSetter, 'Makiswap: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'Makiswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}
