// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockStakingInstance {
    address public activityChecker;
    uint256 public lastCheckpointTime;

    constructor() {
        lastCheckpointTime = block.timestamp;
    }

    function setActivityChecker(address _activityChecker) external {
        activityChecker = _activityChecker;
    }

    function checkpoint() external returns (
        uint256[] memory serviceIds,
        uint256[] memory eligibleServiceIds,
        uint256[] memory eligibleServiceRewards,
        uint256[] memory evictServiceIds
    ) {
        lastCheckpointTime = block.timestamp;
        return (new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0));
    }

    function tsCheckpoint() external view returns (uint256) {
        return lastCheckpointTime;
    }
} 