// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockBalancerRouter {
    address public permit2;

    constructor() {
        permit2 = address(this); // For testing, we'll use the router itself as permit2
    }

    function donate(
        address pool,
        uint256[] memory amountsIn,
        bool wethIsEth,
        bytes memory userData
    ) external payable {}

    function getPermit2() external view returns (address) {
        return permit2;
    }
} 