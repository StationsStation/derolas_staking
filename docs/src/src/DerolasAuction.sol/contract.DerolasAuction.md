# DerolasAuction
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/DerolasAuction.sol)

Main contract for managing rounds, donations, and rewards

*This contract handles the auction mechanism, donation collection, and reward distribution*


## State Variables
### MINIMUM_BALANCE_DONATION_AMOUNT

```solidity
uint256 public immutable MINIMUM_BALANCE_DONATION_AMOUNT = 1_000_000;
```


### assetsInPool

```solidity
uint256 public immutable assetsInPool;
```


### incentiveTokenIndex

```solidity
uint256 public immutable incentiveTokenIndex;
```


### wethIndex

```solidity
uint256 public immutable wethIndex;
```


### incentiveTokenAddress

```solidity
address public immutable incentiveTokenAddress;
```


### balancerRouter

```solidity
address public immutable balancerRouter;
```


### balancerVaultAdmin

```solidity
address public immutable balancerVaultAdmin;
```


### poolId

```solidity
address public immutable poolId;
```


### permit2

```solidity
address public immutable permit2;
```


### currentRound

```solidity
uint256 public currentRound = 1;
```


### owner

```solidity
address public owner;
```


### paramsUpdateRequested

```solidity
bool public paramsUpdateRequested;
```


### _locked

```solidity
uint256 internal _locked = 1;
```


### roundToDonations

```solidity
mapping(uint256 => mapping(address => uint256)) public roundToDonations;
```


### roundToClaimed

```solidity
mapping(uint256 => mapping(address => uint256)) public roundToClaimed;
```


### roundPoints

```solidity
mapping(uint256 => RoundPoint) public roundPoints;
```


### epochDonationActivities

```solidity
mapping(address => uint256) public epochDonationActivities;
```


## Functions
### constructor

*DerolasStaking constructor.*


```solidity
constructor(
    uint256 _minDonation,
    address _balancerRouter,
    address _balancerVaultAdmin,
    address _poolId,
    uint256 _assetsInPool,
    address _incentiveTokenAddress,
    uint256 _incentiveTokenIndex,
    uint256 _wethIndex,
    uint256 _availableRewards,
    uint256 _roundLength
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minDonation`|`uint256`|Minimum round donation.|
|`_balancerRouter`|`address`|Balancer router address.|
|`_balancerVaultAdmin`|`address`||
|`_poolId`|`address`|Pool ID.|
|`_assetsInPool`|`uint256`|Assets in pool.|
|`_incentiveTokenAddress`|`address`|Incentive token address.|
|`_incentiveTokenIndex`|`uint256`|Incentive token index.|
|`_wethIndex`|`uint256`||
|`_availableRewards`|`uint256`|Available rewards.|
|`_roundLength`|`uint256`|Round length.|


### _donateUnclaimedIncentiveTokens

*Donates unclaimed rewards.*


```solidity
function _donateUnclaimedIncentiveTokens(uint256 claimRound) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimRound`|`uint256`|Claim round.|


### _donateEthContribution

*Donates collected contributions.*


```solidity
function _donateEthContribution() internal;
```

### endRound

*Ends an round.*


```solidity
function endRound() external;
```

### claim

*Claims donation based rewards for the previous round*


```solidity
function claim() external;
```

### changeOwner

*Changes contract owner address.*


```solidity
function changeOwner(address newOwner) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|Address of a new owner.|


### changeParams

*Changes round parameters.*


```solidity
function changeParams(uint256 newRoundRewards, uint256 newRoundLength, uint256 minDonation) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRoundRewards`|`uint256`|New round rewards.|
|`newRoundLength`|`uint256`|New round length.|
|`minDonation`|`uint256`|New minimum donation.|


### claimable

*Gets claimable rewards.*


```solidity
function claimable(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Account address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Claimable rewards.|


### estimateTicketPercentage

*Estimates ticket percentage.*


```solidity
function estimateTicketPercentage(uint256 donation) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`donation`|`uint256`|Donation amount.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Ticket percentage.|


### donate

*Donates to the auction contract.*


```solidity
function donate() external payable;
```

### topUpIncentiveBalance

*Top ups incentive balance.*


```solidity
function topUpIncentiveBalance(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount to top up.|


### getCurrentShare

*Gets current share.*


```solidity
function getCurrentShare(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Account address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Current share.|


### getBlocksSinceRoundEnd

*Gets blocks since last round end.*


```solidity
function getBlocksSinceRoundEnd() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Blocks since last round end.|


### getRemainingRoundLength

*Gets remaining round length progress.*


```solidity
function getRemainingRoundLength() public view returns (uint256 remainingRoundLength);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`remainingRoundLength`|`uint256`|Remaining round length.|


### getRoundProgress

*Gets round progress.*


```solidity
function getRoundProgress() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Round progress.|


### getTotalUnclaimed

*Gets total unclaimed rewards.*


```solidity
function getTotalUnclaimed() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total unclaimed rewards.|


### getGameState


```solidity
function getGameState(address user) external view returns (GameState memory state);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|User address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`state`|`GameState`|game state.|


### recoverIncentiveTokenBalance

This function allows the owner to recover the incentive token balance from the contract.

*Recovers the incentive token balance.*


```solidity
function recoverIncentiveTokenBalance() external;
```

### getMultisigNonces

*Gets service multisig nonces.*


```solidity
function getMultisigNonces(address multisig) external view virtual returns (uint256[] memory nonces);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`multisig`|`address`|Service multisig address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nonces`|`uint256[]`|Current donations value.|


### isRatioPass

The ratio pass is true if there was a difference in donations between previous and current checkpoints.

*Checks if the service multisig liveness ratio passes the defined liveness threshold.*


```solidity
function isRatioPass(uint256[] memory curNonces, uint256[] memory lastNonces, uint256)
    external
    view
    virtual
    returns (bool ratioPass);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curNonces`|`uint256[]`|Current service multisig set of a single nonce.|
|`lastNonces`|`uint256[]`|Last service multisig set of a single nonce.|
|`<none>`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ratioPass`|`bool`|True, if the liveness ratio passes the check.|


### receive

*Receive function.*


```solidity
receive() external payable;
```

## Events
### OwnerUpdated

```solidity
event OwnerUpdated(address indexed owner);
```

### DonationReceived

```solidity
event DonationReceived(address indexed donatorAddress, uint256 indexed amount);
```

### TopUpIncentiveReceived

```solidity
event TopUpIncentiveReceived(uint256 indexed amount);
```

### AuctionEnded

```solidity
event AuctionEnded(
    uint256 indexed roundCounter,
    uint256 indexed totalRoundDonations,
    uint256 indexed totalRoundClaimed,
    uint256 availableRewards
);
```

### UnclaimedIncentiveTokensDonated

```solidity
event UnclaimedIncentiveTokensDonated(uint256 indexed amount);
```

### RewardsClaimed

```solidity
event RewardsClaimed(address indexed donatorAddress, uint256 indexed amount);
```

### ParamsUpdated

```solidity
event ParamsUpdated(uint256 indexed nextRound, uint256 availableRewards, uint256 roundLength, uint256 minDonation);
```

### EthDonatedToBalancer

```solidity
event EthDonatedToBalancer(uint256 indexed amount);
```

