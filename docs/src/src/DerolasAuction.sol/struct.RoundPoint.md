# RoundPoint
[Git Source](https://github.com/StationsStation/derolas_staking/blob/1fe30109e452572f612cc88e289dc698fe50d916/src/DerolasAuction.sol)

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

