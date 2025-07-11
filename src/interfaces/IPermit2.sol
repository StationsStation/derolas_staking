// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Permit2 Interface
/// @notice Interface for interacting with Permit2 contract
interface IPermit2 {
    /// @dev Approves a token for a spender.
    /// @param token Token address.
    /// @param spender Account address that will be able to transfer tokens on behalf of the owner.
    /// @param amount Token amount.
    /// @param expiration Expiration timestamp.
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}
