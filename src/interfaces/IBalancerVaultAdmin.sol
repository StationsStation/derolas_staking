// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Balancer Vault Admin Interface
/// @notice Interface for interacting with Balancer's vault admin contract
interface IBalancerVaultAdmin {
    /// @dev Gets the Minimum trade amount for the vault.
    /// @return minimumTradeAmount The minimum trade amount.
    /// This is used to ensure that trades do not occur below a certain threshold.
    function getMinimumTradeAmount() external view returns (uint256);
    /// @dev Gets the balancer vault address.
    /// @return balancerVault The address of the Balancer vault.
    function vault() external view returns (address balancerVault);
}
