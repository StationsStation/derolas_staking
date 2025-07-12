# IBalancerVaultAdmin
[Git Source](https://github.com/StationsStation/derolas_staking/blob/1fe30109e452572f612cc88e289dc698fe50d916/src/interfaces/IBalancerVaultAdmin.sol)

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


