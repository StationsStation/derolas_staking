# INFToken
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/interfaces/IToken.sol)


## Functions
### approve

*Sets token `id` as the allowance of `spender` over the caller's tokens.*


```solidity
function approve(address spender, uint256 id) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|Account address that will be able to transfer the token on behalf of the caller.|
|`id`|`uint256`|Token id.|


### transferFrom

*Transfers a specified token Id.*


```solidity
function transferFrom(address from, address to, uint256 id) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Account address to transfer from.|
|`to`|`address`|Account address to transfer to.|
|`id`|`uint256`|Token id.|


### safeTransferFrom

*Transfers a specified token Id with a callback.*


```solidity
function safeTransferFrom(address from, address to, uint256 id) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Account address to transfer from.|
|`to`|`address`|Account address to transfer to.|
|`id`|`uint256`|Token id.|


