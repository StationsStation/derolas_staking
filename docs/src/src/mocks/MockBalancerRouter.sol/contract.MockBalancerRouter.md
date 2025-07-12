# MockBalancerRouter
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/mocks/MockBalancerRouter.sol)


## State Variables
### permit2

```solidity
address public permit2;
```


## Functions
### constructor


```solidity
constructor();
```

### donate


```solidity
function donate(address pool, uint256[] memory amountsIn, bool wethIsEth, bytes memory userData) external payable;
```

### getPermit2


```solidity
function getPermit2() external view returns (address);
```

