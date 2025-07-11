# GameState
[Git Source](https://github.com/StationsStation/derolas_staking/blob/d97b6f149de1dc071c046d8ac57f88b8ed721406/src/DerolasAuction.sol)

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

