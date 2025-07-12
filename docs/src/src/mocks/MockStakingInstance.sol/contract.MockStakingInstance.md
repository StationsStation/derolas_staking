# MockStakingInstance
[Git Source](https://github.com/StationsStation/derolas_staking/blob/1fe30109e452572f612cc88e289dc698fe50d916/src/mocks/MockStakingInstance.sol)


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

