# MockStakingInstance
[Git Source](https://github.com/StationsStation/derolas_staking/blob/d97b6f149de1dc071c046d8ac57f88b8ed721406/src/mocks/MockStakingInstance.sol)


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

