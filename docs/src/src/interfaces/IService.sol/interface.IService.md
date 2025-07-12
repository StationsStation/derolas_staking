# IService
[Git Source](https://github.com/StationsStation/derolas_staking/blob/d97b6f149de1dc071c046d8ac57f88b8ed721406/src/interfaces/IService.sol)


## Functions
### create

*Creates a new service.*


```solidity
function create(
    address serviceOwner,
    address token,
    bytes32 configHash,
    uint32[] memory agentIds,
    AgentParams[] memory agentParams,
    uint32 threshold
) external returns (uint256 serviceId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceOwner`|`address`|Individual that creates and controls a service.|
|`token`|`address`|ERC20 token address for the security deposit, or ETH.|
|`configHash`|`bytes32`|IPFS hash pointing to the config metadata.|
|`agentIds`|`uint32[]`|Canonical agent Ids.|
|`agentParams`|`AgentParams[]`|Number of agent instances and required bond to register an instance in the service.|
|`threshold`|`uint32`|Threshold for a multisig composed by agents.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Created service Id.|


### activateRegistration

*Activates the service and its sensitive components.*


```solidity
function activateRegistration(uint256 serviceId) external payable returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Correspondent service Id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|True, if function executed successfully.|


### registerAgents

*Registers agent instances.*


```solidity
function registerAgents(uint256 serviceId, address[] memory agentInstances, uint32[] memory agentIds)
    external
    payable
    returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id to be updated.|
|`agentInstances`|`address[]`|Agent instance addresses.|
|`agentIds`|`uint32[]`|Canonical Ids of the agent correspondent to the agent instance.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|True, if function executed successfully.|


### deploy

*Creates multisig instance controlled by the set of service agent instances and deploys the service.*


```solidity
function deploy(uint256 serviceId, address multisigImplementation, bytes memory data)
    external
    returns (address multisig);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Correspondent service Id.|
|`multisigImplementation`|`address`|Multisig implementation address.|
|`data`|`bytes`|Data payload for the multisig creation.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`multisig`|`address`|Address of the created multisig.|


### terminate

*Terminates the service.*


```solidity
function terminate(uint256 serviceId) external returns (bool success, uint256 refund);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id to be updated.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|True, if function executed successfully.|
|`refund`|`uint256`|Refund to return to the serviceOwner.|


### unbond

*Unbonds agent instances of the operator from the service.*


```solidity
function unbond(uint256 serviceId) external returns (bool success, uint256 refund);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|True, if function executed successfully.|
|`refund`|`uint256`|The amount of refund returned to the operator.|


### serviceRegistry

*Gets the serviceRegistry address.*


```solidity
function serviceRegistry() external returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|serviceRegistry address.|


### serviceRegistryTokenUtility

*Gets the serviceRegistryTokenUtility address.*


```solidity
function serviceRegistryTokenUtility() external returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|serviceRegistryTokenUtility address.|


### mapServices

*Gets the service instance from the map of services.*


```solidity
function mapServices(uint256 serviceId)
    external
    view
    returns (
        uint96 securityDeposit,
        address multisig,
        bytes32 configHash,
        uint32 threshold,
        uint32 maxNumAgentInstances,
        uint32 numAgentInstances,
        uint8 state
    );
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`securityDeposit`|`uint96`|Registration activation deposit.|
|`multisig`|`address`|Service multisig address.|
|`configHash`|`bytes32`|IPFS hashes pointing to the config metadata.|
|`threshold`|`uint32`|Agent instance signers threshold.|
|`maxNumAgentInstances`|`uint32`|Total number of agent instances.|
|`numAgentInstances`|`uint32`|Actual number of agent instances.|
|`state`|`uint8`|Service state.|


## Structs
### AgentParams

```solidity
struct AgentParams {
    uint32 slots;
    uint96 bond;
}
```

