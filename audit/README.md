# Internal audit of derolas_stacking
The review has been performed based on the contract code in the following repository:<br>
`https://github.com/StationsStation/derolas_staking` <br>
commit: `7a2b67ba902a193b6fd4b26a8138a52ec13c4044` <br> 

## Objectives
The audit focused on contracts in this repo.

## Issues
### Medium: withdrawIncentiveTokenBalance()
You can't take away by owner what has already been promised for rewards and donations have already been made in round - 1.
```
        uint256 claimRound = currentRound - 1;
        uint256 totalRoundDonations = roundPoints[claimRound].totalDonated;
        if(totalRoundDonations > 0) {
            Do not touch as min roundPoints[claimRound].availableRewards
        }
```

### Medium: Desync behavior via sending ETH to contract
Sending native tokens to a contract changes the balance, but does not change the variables.
Not checked msg.value vs roundPoints[curRound].minDonation
I recommend removing the function if it has no other use or limiting it to the owner only.
```
    /// @dev Receive function.
    receive() external payable {}
```
[]

### Low: No emit
```
No emit in withdrawIncentiveTokenBalance()
```
[]

### Low: div by zero
No check totalRoundDonations == 0.
This is not a problem, but there will be an arithmetic exception that is not clear to the user.
```
uint256 amount = (donation * roundPoints[claimRound].availableRewards) / totalRoundDonations;
```
[]

### Notes: Donate flag in pool
Pools with the donate feature enabled cannot be nested, composable and cannot be used in lending protocols.
Reason is a natural way to manipulate getRate() via donate.
Ref: https://docs.balancer.fi/developer-reference/contracts/router-api.html#donate
```text
This liquidity type is disabled by default, and is only useful in certain limited use cases (e.g., pools with exit fees). Pools that support donation have special security considerations. In particular, their rates are trivially manipulable, so they cannot be nested inside other pools. Use with care!
```
[]

### Notes: Approve(amount) vs Approve(0) && Approve(amount)
Not required for OLAS tokens.
For USDT current implementation is a mandatory code, because
```
    require((value == 0) || (allowed[msg.sender][spender] == 0));
    allowed[msg.sender][spender] = value;
```
Before using other tokens, check their behavior on call approve(0).
Ref:
```
        IToken(incentiveTokenAddress).approve(permit2, 0);
        IToken(incentiveTokenAddress).approve(permit2, unclaimedAmount);
```
[]

### Notes: Not needing check
```
        if (totalRoundDonations == 0) {
            return 1e18; // full share
        }

        return (donation * 1e18) / (totalRoundDonations + donation);
        --> (donation * 1e18) / (0 + donation)
        --> 1e18
```
[]

### Notes: Confusing calculations
Confusing calculations. Actually the point is that if `roundToClaimed[claimRound][account] > 0` then you need to return 0.
```
        uint256 amount = (donation * roundPoints[claimRound].availableRewards) / totalRoundDonations;
        uint256 claimedAmount = roundToClaimed[claimRound][account];
        return amount - claimedAmount;
```
[]