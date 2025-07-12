# IStaking
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/interfaces/IStaking.sol)


## Functions
### stakingToken

*Gets service staking token.*


```solidity
function stakingToken() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Service staking token address.|


### minStakingDeposit

*Gets minimum service staking deposit value required for staking.*


```solidity
function minStakingDeposit() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Minimum service staking deposit.|


### numAgentInstances

*Gets number of required agent instances in the service.*


```solidity
function numAgentInstances() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Number of agent instances.|


### threshold

*Gets the service threshold.*


```solidity
function threshold() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Threshold.|


### stake

*Stakes the service.*


```solidity
function stake(uint256 serviceId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|


### unstake

*Unstakes the service with collected reward, if available.*


```solidity
function unstake(uint256 serviceId) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|reward Staking reward.|


### claim

*Claims rewards for the service without an additional checkpoint call.*


```solidity
function claim(uint256 serviceId) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Staking reward.|


### verifyInstance

*Verifies a service staking contract instance.*


```solidity
function verifyInstance(address instance) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`instance`|`address`|Service staking proxy instance.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True, if verification is successful.|


