# IPermit2
[Git Source](https://github.com/StationsStation/derolas_staking/blob/1fe30109e452572f612cc88e289dc698fe50d916/src/interfaces/IPermit2.sol)

Interface for interacting with Permit2 contract


## Functions
### approve

*Approves a token for a spender.*


```solidity
function approve(address token, address spender, uint160 amount, uint48 expiration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address.|
|`spender`|`address`|Account address that will be able to transfer tokens on behalf of the owner.|
|`amount`|`uint160`|Token amount.|
|`expiration`|`uint48`|Expiration timestamp.|


