# IBalancerVaultAdmin
[Git Source](https://github.com/StationsStation/derolas_staking/blob/d97b6f149de1dc071c046d8ac57f88b8ed721406/src/interfaces/IBalancerVaultAdmin.sol)

Interface for interacting with Balancer's vault admin contract


## Functions
### getMinimumTradeAmount

*Gets the Minimum trade amount for the vault.*


```solidity
function getMinimumTradeAmount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|minimumTradeAmount The minimum trade amount. This is used to ensure that trades do not occur below a certain threshold.|


