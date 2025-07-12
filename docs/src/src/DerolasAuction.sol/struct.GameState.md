# GameState
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/DerolasAuction.sol)

Stores information about the current game state

*Game state struct.*


```solidity
struct GameState {
    uint256 roundLength;
    uint256 currentRound;
    uint256 roundEndBlock;
    uint256 minimumDonation;
    uint256 blocksRemaining;
    uint256 roundRewards;
    uint256 totalDonated;
    uint256 totalClaimed;
    uint256 incentiveBalance;
    uint256 userCurrentDonation;
    uint256 userCurrentShare;
    uint256 userClaimable;
    bool hasClaimed;
    bool canPlayGame;
}
```

