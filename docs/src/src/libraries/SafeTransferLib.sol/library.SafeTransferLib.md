# SafeTransferLib
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/libraries/SafeTransferLib.sol)

*The implementation corrects SafeTransferLib.sol that was fully copied from autonolas-registries repository:
https://github.com/valory-xyz/autonolas-registries/blob/main/contracts/utils/SafeTransferLib.sol,
while initially it was sourced from the audited MIT-licensed solmate code repository:
https://github.com/transmissions11/solmate/blob/v7/src/utils/SafeTransferLib.sol
The original library imports the `ERC20` abstract token contract, and thus embeds all that contract
related code that is not needed. In this version, `ERC20` is swapped with the `address` representation.
Also, the final `require` statement is modified with this contract own `revert` statement.*


## Functions
### safeTransferFrom

*Safe token transferFrom implementation.*


```solidity
function safeTransferFrom(address token, address from, address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address.|
|`from`|`address`|Address to transfer tokens from.|
|`to`|`address`|Address to transfer tokens to.|
|`amount`|`uint256`|Token amount.|


### safeTransfer

The implementation is fully copied from the audited MIT-licensed solmate code repository:
https://github.com/transmissions11/solmate/blob/v7/src/utils/SafeTransferLib.sol
The original library imports the `ERC20` abstract token contract, and thus embeds all that contract
related code that is not needed. In this version, `ERC20` is swapped with the `address` representation.
Also, the final `require` statement is modified with this contract own `revert` statement.

*Safe token transfer implementation.*


```solidity
function safeTransfer(address token, address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address.|
|`to`|`address`|Address to transfer tokens to.|
|`amount`|`uint256`|Token amount.|


