// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

// ** GLOBAL IMPORTS ** //
// import 'makiswap-core/contracts/interfaces/IMakiswapFactory.sol';

// ** LOCAL IMPORTS ** //
import './interfaces/IMakiswapFactory.sol';
import './MakiswapPair.sol';



contract MakiswapFactory is IMakiswapFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event V2PairCreated(address indexed token0, address indexed token1, address pair, uint);

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
        require(tokenA != tokenB, 'MakiswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MakiswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'MakiswapV2: PAIR_EXISTS'); // single check is sufficient
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
        require(msg.sender == feeToSetter, 'MakiswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external {
        require(msg.sender == feeToSetter, 'MakiswapV2: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'MakiswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}
