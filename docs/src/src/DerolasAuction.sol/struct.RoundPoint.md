# RoundPoint
[Git Source](https://github.com/StationsStation/derolas_staking/blob/d97b6f149de1dc071c046d8ac57f88b8ed721406/src/DerolasAuction.sol)

Stores information about a specific round

*Round point struct.*


```solidity
struct RoundPoint {
    uint256 availableRewards;
    uint256 totalDonated;
    uint256 totalClaimed;
    uint256 length;
    uint256 minDonation;
    uint256 endBlock;
}
```

