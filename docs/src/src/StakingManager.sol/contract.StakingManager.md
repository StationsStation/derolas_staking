# StakingManager
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/StakingManager.sol)

**Inherits:**
ERC721TokenReceiver


## State Variables
### VERSION

```solidity
string public constant VERSION = "0.1.0";
```


### NUM_AGENT_INSTANCES

```solidity
uint256 public constant NUM_AGENT_INSTANCES = 1;
```


### THRESHOLD

```solidity
uint256 public constant THRESHOLD = 1;
```


### agentId

```solidity
uint256 public immutable agentId;
```


### configHash

```solidity
bytes32 public immutable configHash;
```


### serviceManager

```solidity
address public immutable serviceManager;
```


### olas

```solidity
address public immutable olas;
```


### serviceRegistry

```solidity
address public immutable serviceRegistry;
```


### serviceRegistryTokenUtility

```solidity
address public immutable serviceRegistryTokenUtility;
```


### stakingFactory

```solidity
address public immutable stakingFactory;
```


### safeMultisig

```solidity
address public immutable safeMultisig;
```


### fallbackHandler

```solidity
address public immutable fallbackHandler;
```


### _nonce

```solidity
uint256 internal _nonce;
```


### _locked

```solidity
uint256 internal _locked = 1;
```


### mapAccountServiceInfo

```solidity
mapping(address => ServiceInfo) public mapAccountServiceInfo;
```


## Functions
### constructor

*LiquidityManager constructor.*


```solidity
constructor(
    address _serviceManager,
    address _olas,
    address _stakingFactory,
    address _safeMultisig,
    address _fallbackHandler,
    uint256 _agentId,
    bytes32 _configHash
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_serviceManager`|`address`|Service manager address.|
|`_olas`|`address`|OLAS token address.|
|`_stakingFactory`|`address`|Staking factory address.|
|`_safeMultisig`|`address`|Safe multisig address.|
|`_fallbackHandler`|`address`|Multisig fallback handler address.|
|`_agentId`|`uint256`|Agent Id.|
|`_configHash`|`bytes32`|Service config hash.|


### _createAndDeploy

*Creates and deploys a service.*


```solidity
function _createAndDeploy(address token, uint256 minStakingDeposit)
    internal
    returns (uint256 serviceId, address multisig);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Staking token address.|
|`minStakingDeposit`|`uint256`|Min staking deposit value.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Minted service Id.|
|`multisig`|`address`|Service multisig.|


### _stake

*Stakes the already deployed service.*


```solidity
function _stake(uint256 serviceId, address multisig, address stakingInstance) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|
|`multisig`|`address`|Corresponding service multisig.|
|`stakingInstance`|`address`|Staking instance.|


### createAndStake

The service cannot be registered again if it is currently staked.

*Creates and deploys a service, and stakes it with a specified staking contract.*


```solidity
function createAndStake(address stakingInstance) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`stakingInstance`|`address`|Staking instance address.|


### stake

*Stakes the already deployed service.*


```solidity
function stake(uint256 serviceId, address stakingInstance) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`serviceId`|`uint256`|Service Id.|
|`stakingInstance`|`address`|Staking instance.|


### unstake

*Unstakes service Id corresponding to the msg.sender and clears the record.*


```solidity
function unstake() external;
```

### claim

*Claims rewards for the service corresponding to msg.sender.*


```solidity
function claim() external returns (uint256 reward);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`uint256`|Staking reward.|


### receive

*receives back wei-s from service registries*


```solidity
receive() external payable;
```

## Events
### CreatedAndStaked

```solidity
event CreatedAndStaked(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
```

### Staked

```solidity
event Staked(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
```

### Unstaked

```solidity
event Unstaked(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
```

### Claimed

```solidity
event Claimed(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
```

