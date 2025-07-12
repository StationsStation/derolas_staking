# MockStakingInstance
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/mocks/MockStakingInstance.sol)


## State Variables
### activityChecker

```solidity
address public activityChecker;
```


### lastCheckpointTime

```solidity
uint256 public lastCheckpointTime;
```


## Functions
### constructor


```solidity
constructor();
```

### setActivityChecker


```solidity
function setActivityChecker(address _activityChecker) external;
```

### checkpoint


```solidity
function checkpoint()
    external
    returns (
        uint256[] memory serviceIds,
        uint256[] memory eligibleServiceIds,
        uint256[] memory eligibleServiceRewards,
        uint256[] memory evictServiceIds
    );
```

### tsCheckpoint


```solidity
function tsCheckpoint() external view returns (uint256);
```

