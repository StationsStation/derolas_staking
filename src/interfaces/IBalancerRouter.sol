// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Balancer Router Interface
/// @notice Interface for interacting with Balancer's router contract
interface IBalancerRouter {
    /// @dev Donates tokens to a pool.
    /// @param pool Pool address.
    /// @param amountsIn Amounts of tokens to donate.
    /// @param wethIsEth Whether WETH is ETH.
    /// @param userData User data.
    function donate(address pool, uint256[] memory amountsIn, bool wethIsEth, bytes memory userData) external payable;

    /// @dev Gets permit2 address.
    /// @return permit2 address.
    function getPermit2() external view returns (address);
}
