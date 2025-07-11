# IToken
[Git Source](https://github.com/StationsStation/derolas_staking/blob/d97b6f149de1dc071c046d8ac57f88b8ed721406/src/interfaces/IToken.sol)


## Functions
### transfer

*Transfers the token amount.*


```solidity
function transfer(address to, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Address to transfer to.|
|`amount`|`uint256`|The amount to transfer.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the function execution is successful.|


### transferFrom

*Transfers the token amount that was previously approved up until the maximum allowance.*


```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Account address to transfer from.|
|`to`|`address`|Account address to transfer to.|
|`amount`|`uint256`|Amount to transfer to.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the function execution is successful.|


### approve

*Sets `amount` as the allowance of `spender` over the caller's tokens.*


```solidity
function approve(address spender, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|Account address that will be able to transfer tokens on behalf of the caller.|
|`amount`|`uint256`|Token amount.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the function execution is successful.|


### balanceOf

*Returns the amount of tokens owned by `account`.*


```solidity
function balanceOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Account address to check the balance of.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of tokens owned by `account`.|


