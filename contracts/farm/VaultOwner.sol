// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'maki-swap-lib/contracts/token/HRC20/SafeHRC20.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import './libs/IMasterChef.sol';
import './MakiVault.sol';

pragma solidity ^0.6.12;

contract VaultOwner is Ownable {
    using SafeHRC20 for IHRC20;

    MakiVault public immutable makiVault;

    /**
     * @notice Constructor
     * @param _makiVaultAddress: MakiVault contract address
     */
    constructor(address _makiVaultAddress) public {
        makiVault = MakiVault(_makiVaultAddress);
    }

    /**
     * @notice Sets admin address to this address
     * @dev Only callable by the contract owner.
     * It makes the admin == owner.
     */
    function setAdmin() external onlyOwner {
        makiVault.setAdmin(address(this));
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        makiVault.setTreasury(_treasury);
    }

    /**
     * @notice Sets performance fee
     * @dev Only callable by the contract owner.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        makiVault.setPerformanceFee(_performanceFee);
    }

    /**
     * @notice Sets call fee
     * @dev Only callable by the contract owner.
     */
    function setCallFee(uint256 _callFee) external onlyOwner {
        makiVault.setCallFee(_callFee);
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        makiVault.setWithdrawFee(_withdrawFee);
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyOwner {
        makiVault.setWithdrawFeePeriod(_withdrawFeePeriod);
    }

    /**
     * @notice Withdraw unexpected tokens sent to the Maki Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        makiVault.inCaseTokensGetStuck(_token);
        uint256 amount = IHRC20(_token).balanceOf(address(this));
        IHRC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner {
        makiVault.pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner {
        makiVault.unpause();
    }
}
