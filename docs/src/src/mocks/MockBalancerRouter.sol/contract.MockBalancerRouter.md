# MockBalancerRouter
[Git Source](https://github.com/StationsStation/derolas_staking/blob/1fe30109e452572f612cc88e289dc698fe50d916/src/mocks/MockBalancerRouter.sol)


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

