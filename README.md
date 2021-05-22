# About the Maki Protocol Repo
This repository is designed as a container for the contracts that play the most pivotal role in the farm and exchange components of the Maki Protocol, which is a Pancakeswap fork designed to operate on Huobi.
___
# Contracts for Audit
## Primary Exchange Contracts
    -   MakiswapFactory.sol
    -   MakiswapRouter.sol
    -   MakiswapPair.sol

## Primary Farm Contracts
    -   SoyBar.sol
    -   MakiToken.sol
    -   MasterChef.sol
    -   SousChef.sol
___
# Contracts Directory
-   Contains all the smart contracts relevant for direct inspection. This directory consists of two isolated sections -- exchange and farm. 
-   When possible, Open Zeppelin smart contracts are imported directly, however, some contracts required customization and those files are contains in this repository and stored public on NPM. 
-   In such instances, the Pancakeswap revision is forked and altered *strictly* where naming convention required, leaving the logic unscathed.

___
# (Auto)-Generate Flat Contracts
- We've enabled our Makiswap Protocol repository to automagically produce flats using the truffle-flattener.
- Use the `flatten` scripts to generate fresh, flattened contracts stored in the *flats* directory. 

```
yarn flatten:chefs 
```
___
## Main Directory Composition
___
-   [EXCHANGE](#exchange-and-farm) or [FARM](#exchange-and-farm)
    -   [Flats](#flats-and-libraries)
    -   [Interfaces](#interfaces-and-token)
    -   [Token](#interfaces-and-token)
    -   [Libraries](#flats-and-libraries)


[Notes on Libraries](#notes-on-libraries)

___
## Exchange and Farm
___
- This repository contains the smart contracts for the **exchange** and the **farm** component of MakiSwap. 
- These are included together to benefit the auditor tasked with reviewing each series of contracts.
___
## Interfaces and Token
___

- **Interfaces Directory**: includes the interfaces referenced in the main smart contracts for each respective sub-section.
- **Token Directory**: includes the smart contracts that are inherited by the MakiToken.sol, namely HRC20.sol and SafeHRC20.sol, which are designed to mirror the OZ smart contracts for the ERC equivalents.
___
## Flats and Libraries
___
- **Flats Directory**: contains the flattened versions of the smart contracts.
- **Libraries Directory**: contains the smart contracts that are referenced via an import, stored publicly in node package manager (npm).
- **More Details** 
    -   Please feel free to review each component in the context of their respective repositories as listed below,
        -   [maki-swap-lib](https://github.com/makiswap-protocol/maki-swap-lib)
        -   [maki-swap-core](https://github.com/makiswap-protocol/maki-swap-core)
        -   [maki-swap-periphery](https://github.com/makiswap-protocol/maki-swap-periphery)
        -   [maki-farm](https://github.com/makiswap-protocol/maki-farm)

### Notes on Libraries
- Conventionally, devs import Open Zeppelin smart contracts. However, given Huobi is the smart chain of choice, in instances where ERC20 / BEP20 is referenced a new variant of the contract in question is forked and becomes a unique contract in name only, not in logic.
- The schema of swap-lib, swap-core, and swap-periphery are modeled exactly like Pancakeswap, from which the repositories are forked and altered to meet the context of Huobi in lieu of Binance.

## Deployed Contracts (Testnet)
- [MakiToken.sol](https://testnet.hecoinfo.com/address/0x6aDda9A700e4821E8d11016fdda73F8f344b3a8e#code): 0x6aDda9A700e4821E8d11016fdda73F8f344b3a8e
- [MakiswapFactory.sol](https://testnet.hecoinfo.com/address/0xaa4f13E821aD5e0dF3B257D99BA12fd4618d9b26#code): 0xaa4f13E821aD5e0dF3B257D99BA12fd4618d9b26
    - `INIT_CODE_PAIR_HASH`: 0xcf5b20a7c8f9f999a04f5d25a7219dfb7aac456d5f8e07a8a9056ac3eb2ed012
- [MakiswapRouter.sol](https://testnet.hecoinfo.com/address/0x6BAF17e8D077011b22848EDbDB4fb6a511096508#code): 0x6BAF17e8D077011b22848EDbDB4fb6a511096508
- [SoyBar.sol](https://testnet.hecoinfo.com/address/0xE318C623744Ea58Fc36c6d54C63cFd3e55482745#code): 0xE318C623744Ea58Fc36c6d54C63cFd3e55482745
- [MasterChef.sol](https://testnet.hecoinfo.com/address/0xc83177C4Cc8a10E9595b8df24Da5925622ED09Eb#code): 0xc83177C4Cc8a10E9595b8df24Da5925622ED09Eb
- [SousChef.sol](https://testnet.hecoinfo.com/address/0xE318C623744Ea58Fc36c6d54C63cFd3e55482745#code): 0xE318C623744Ea58Fc36c6d54C63cFd3e55482745