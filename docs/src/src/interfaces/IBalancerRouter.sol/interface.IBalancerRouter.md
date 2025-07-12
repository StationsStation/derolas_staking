# IBalancerRouter
[Git Source](https://github.com/StationsStation/derolas_staking/blob/1fe30109e452572f612cc88e289dc698fe50d916/src/interfaces/IBalancerRouter.sol)

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


