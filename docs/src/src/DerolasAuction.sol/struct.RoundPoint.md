# RoundPoint
[Git Source](https://github.com/StationsStation/derolas_staking/blob/8bc08887a8e04569d108bb4c8a9f56cd69d8deaa/src/DerolasAuction.sol)

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

