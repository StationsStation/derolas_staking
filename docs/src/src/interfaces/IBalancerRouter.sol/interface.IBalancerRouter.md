# IBalancerRouter
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/interfaces/IBalancerRouter.sol)

Interface for interacting with Balancer's router contract


## Functions
### donate

*Donates tokens to a pool.*


```solidity
function donate(address pool, uint256[] memory amountsIn, bool wethIsEth, bytes memory userData) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`address`|Pool address.|
|`amountsIn`|`uint256[]`|Amounts of tokens to donate.|
|`wethIsEth`|`bool`|Whether WETH is ETH.|
|`userData`|`bytes`|User data.|


### getPermit2

*Gets permit2 address.*


```solidity
function getPermit2() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|permit2 address.|


