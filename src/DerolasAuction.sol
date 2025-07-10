// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IToken} from "./interfaces/IToken.sol";
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";

/// @title Balancer Router Interface
/// @notice Interface for interacting with Balancer's router contract
interface IBalancerRouter {
    /// @dev Donates tokens to a pool.
    /// @param pool Pool address.
    /// @param amountsIn Amounts of tokens to donate.
    /// @param wethIsEth Whether WETH is ETH.
    /// @param userData User data.
    function donate(address pool, uint256[] memory amountsIn, bool wethIsEth, bytes memory userData) external payable;

    /// @dev Gets permit2 address.
    /// @return permit2 address.
    function getPermit2() external view returns (address);
}

/// @title Permit2 Interface
/// @notice Interface for interacting with Permit2 contract
interface IPermit2 {
    /// @dev Approves a token for a spender.
    /// @param token Token address.
    /// @param spender Account address that will be able to transfer tokens on behalf of the owner.
    /// @param amount Token amount.
    /// @param expiration Expiration timestamp.
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}

/// @dev Round point struct.
/// @notice Stores information about a specific round
struct RoundPoint {
    uint256 availableRewards; // Total rewards available for this round
    uint256 totalDonated; // Total amount donated in this round
    uint256 totalClaimed; // Total amount claimed in this round
    uint256 length; // Length of this round in blocks
    uint256 minDonation; // Minimum donation amount for this round
    uint256 endBlock; // End block of this round
}

/// @dev Game state struct.
/// @notice Stores information about the current game state
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

/// @title Derolas Auction Contract
/// @notice Main contract for managing rounds, donations, and rewards
/// @dev This contract handles the auction mechanism, donation collection, and reward distribution
contract DerolasAuction {
    // Events
    event OwnerUpdated(address indexed owner);
    event DonationReceived(address indexed donatorAddress, uint256 indexed amount);
    event TopUpIncentiveReceived(uint256 indexed amount);
    event AuctionEnded(
        uint256 indexed roundCounter,
        uint256 indexed totalRoundDonations,
        uint256 indexed totalRoundClaimed,
        uint256 availableRewards
    );
    event UnclaimedRewardsDonated(uint256 indexed amount);
    event RewardsClaimed(address indexed donatorAddress, uint256 indexed amount);
    event ParamsUpdated(
        uint256 indexed nextRound,
        uint256 availableRewards,
        uint256 roundLength,
        uint256 minDonation
    );

    // Assets in pool
    uint256 public immutable assetsInPool;
    // Incentive token index
    uint256 public immutable incentiveTokenIndex;
    // Incentive token address
    address public immutable incentiveTokenAddress;
    // Balancer router address
    address public immutable balancerRouter;
    // Pool ID
    address public immutable poolId;
    // Permit2 address
    address public immutable permit2;

    // Round counter
    uint256 public currentRound = 1;
    // Contract owner address
    address public owner;
    // Params update request status
    bool public paramsUpdateRequested;

    // Reentrancy lock
    uint256 internal _locked = 1;

    // Mapping of round => (mapping of donator => amount donated)
    mapping(uint256 => mapping(address => uint256)) public roundToDonations;
    // Mapping of round => (mapping of claimer => amount claimed)
    mapping(uint256 => mapping(address => uint256)) public roundToClaimed;
    // Mapping of round => round points
    mapping(uint256 => RoundPoint) public roundPoints;
    // Mapping of donator => amount donated
    mapping(address => uint256) public epochDonationActivities;

    /// @dev DerolasStaking constructor.
    /// @param _minDonation Minimum round donation.
    /// @param _balancerRouter Balancer router address.
    /// @param _poolId Pool ID.
    /// @param _assetsInPool Assets in pool.
    /// @param _incentiveTokenAddress Incentive token address.
    /// @param _incentiveTokenIndex Incentive token index.
    /// @param _availableRewards Available rewards.
    /// @param _roundLength Round length.
    constructor(
        uint256 _minDonation,
        address _balancerRouter,
        address _poolId,
        uint256 _assetsInPool,
        address _incentiveTokenAddress,
        uint256 _incentiveTokenIndex,
        uint256 _availableRewards,
        uint256 _roundLength
    ) {
        balancerRouter = _balancerRouter;
        poolId = _poolId;
        assetsInPool = _assetsInPool;
        incentiveTokenAddress = _incentiveTokenAddress;
        incentiveTokenIndex = _incentiveTokenIndex;
        permit2 = IBalancerRouter(_balancerRouter).getPermit2();
        roundPoints[1].availableRewards = _availableRewards;
        roundPoints[1].length = _roundLength;
        roundPoints[1].minDonation = _minDonation;

        roundPoints[0].endBlock = block.number;
        owner = msg.sender;
    }

    /// @dev Donates unclaimed rewards.
    /// @param claimRound Claim round.
    function _donateUnclaimedRewards(uint256 claimRound) internal {
        uint256 unclaimedAmount = roundPoints[claimRound].availableRewards - roundPoints[claimRound].totalClaimed;
        if (unclaimedAmount == 0) {
            return;
        }

        // TODO This must be resolved to not revert
        require(
            IToken(incentiveTokenAddress).balanceOf(address(this)) >= unclaimedAmount,
            "Not enough incentive balance to donate"
        );

        uint256[] memory amountsIn = new uint256[](assetsInPool);
        amountsIn[incentiveTokenIndex] = unclaimedAmount;

        IToken(incentiveTokenAddress).approve(permit2, 0);
        IToken(incentiveTokenAddress).approve(permit2, unclaimedAmount);
        IPermit2(permit2).approve(
            incentiveTokenAddress, balancerRouter, uint160(unclaimedAmount), uint48(block.timestamp + 1 days)
        );
        IBalancerRouter(balancerRouter).donate(poolId, amountsIn, true, "");

        emit UnclaimedRewardsDonated(unclaimedAmount);
    }

    /// @dev Ends an round.
    function endRound() external {
        // Reentrancy guard
        require(_locked == 1, "ReentrancyGuard");
        _locked = 2;

        uint256 curRound = currentRound;
        uint256 claimRound = curRound - 1;
        require(block.number > roundPoints[claimRound].endBlock + roundPoints[curRound].length, "Round not over");

        _donateUnclaimedRewards(claimRound);

        uint256 nextRound = curRound + 1;

        if (!paramsUpdateRequested) {
            roundPoints[nextRound].availableRewards = roundPoints[curRound].availableRewards;
            roundPoints[nextRound].length = roundPoints[curRound].length;
        }

        roundPoints[curRound].endBlock = block.number;
        currentRound = nextRound;

        emit AuctionEnded(
            curRound,
            roundPoints[curRound].totalDonated,
            roundPoints[claimRound].totalClaimed,
            roundPoints[curRound].availableRewards
        );

        _locked = 1;
    }

    /// @dev Claims donation based rewards for the previous round
    function claim() external {
        require(_locked == 1, "ReentrancyGuard");
        _locked = 2;

        uint256 claimRound = currentRound - 1;
        require(roundPoints[claimRound].endBlock > 0, "Round not ended yet");
        require(roundToClaimed[claimRound][msg.sender] == 0, "Already claimed");

        uint256 donation = roundToDonations[claimRound][msg.sender];
        require(donation > 0, "No donation found");

        uint256 totalRoundDonations = roundPoints[claimRound].totalDonated;
        require(totalRoundDonations > 0, "No donations this round");

        uint256 amount = (donation * roundPoints[claimRound].availableRewards) / totalRoundDonations;
        require(amount > 0, "Nothing to claim");
        require(IToken(incentiveTokenAddress).balanceOf(address(this)) >= amount, "Not enough rewards");

        roundToClaimed[claimRound][msg.sender] = amount;
        roundPoints[claimRound].totalClaimed += amount;

        SafeTransferLib.safeTransfer(incentiveTokenAddress, msg.sender, amount);

        emit RewardsClaimed(msg.sender, amount);

        _locked = 1;
    }

    /// @dev Changes contract owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external virtual {
        // Check current contract owner
        require(msg.sender == owner, "Unauthorized account");
        require(newOwner != address(0), "Zero address");

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes round parameters.
    /// @param newRoundRewards New round rewards.
    /// @param newRoundLength New round length.
    /// @param minDonation New minimum donation.
    function changeParams(
        uint256 newRoundRewards,
        uint256 newRoundLength,
        uint256 minDonation
    ) external {
        require(msg.sender == owner, "Unauthorized account");

        uint256 nextRound = currentRound + 1;
        roundPoints[nextRound].availableRewards = newRoundRewards;
        roundPoints[nextRound].length = newRoundLength;
        roundPoints[nextRound].minDonation = minDonation;
        paramsUpdateRequested = true;

        emit ParamsUpdated(nextRound, newRoundRewards, newRoundLength, minDonation);
    }

    /// @dev Gets claimable rewards.
    /// @param account Account address.
    /// @return Claimable rewards.
    function claimable(address account) external view returns (uint256) {
        uint256 claimRound = currentRound - 1;
        uint256 donation = roundToDonations[claimRound][account];
        uint256 totalRoundDonations = roundPoints[claimRound].totalDonated;

        if (donation == 0 || totalRoundDonations == 0) {
            return 0;
        }

        // Calculate rewards
        uint256 amount = (donation * roundPoints[claimRound].availableRewards) / totalRoundDonations;
        require(IToken(incentiveTokenAddress).balanceOf(address(this)) >= amount, "Not enough rewards");

        return amount;
    }

    /// @dev Estimates ticket percentage.
    /// @param donation Donation amount.
    /// @return Ticket percentage.
    function estimateTicketPercentage(uint256 donation) external view returns (uint256) {
        uint256 curRound = currentRound;
        require(donation >= roundPoints[curRound].minDonation, "Minimum donation not met");
        require(
            IToken(incentiveTokenAddress).balanceOf(address(this)) >= roundPoints[curRound].availableRewards,
            "Not enough rewards to play the game"
        );

        uint256 totalRoundDonations = roundPoints[curRound].totalDonated;
        if (totalRoundDonations == 0) {
            return 1e18; // full share
        }

        return (donation * 1e18) / totalRoundDonations;
    }

    /// @dev Donates to the auction contract.
    function donate() external payable {
        // Reentrancy guard
        require(_locked == 1, "ReentrancyGuard");
        _locked = 2;

        uint256 curRound = currentRound;
        require(msg.value >= roundPoints[curRound].minDonation, "Donation amount is less than the minimum donation");
        require(
            IToken(incentiveTokenAddress).balanceOf(address(this)) >= roundPoints[curRound].availableRewards,
            "Not enough rewards to play the game"
        );

        require(roundToDonations[curRound][msg.sender] == 0, "Already donated this round");

        roundPoints[curRound].totalDonated += msg.value;
        roundToDonations[curRound][msg.sender] = msg.value;
        epochDonationActivities[msg.sender] += msg.value;

        emit DonationReceived(msg.sender, msg.value);

        _locked = 1;
    }

    /// @dev Top ups incentive balance.
    /// @param amount Amount to top up.
    function topUpIncentiveBalance(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        SafeTransferLib.safeTransferFrom(incentiveTokenAddress, msg.sender, address(this), amount);

        emit TopUpIncentiveReceived(amount);
    }

    /// @dev Gets current share.
    /// @param account Account address.
    /// @return Current share.
    function getCurrentShare(address account) external view returns (uint256) {
        uint256 curRound = currentRound;
        uint256 donation = roundToDonations[curRound][account];
        if (donation == 0) {
            return 0; // No donation, no share
        }
        return (donation * 1e18) / roundPoints[curRound].totalDonated;
    }

    /// @dev Gets blocks since last round end.
    /// @return Blocks since last round end.
    function getBlocksSinceRoundEnd() external view returns (uint256) {
        return block.number - roundPoints[currentRound - 1].endBlock;
    }

    /// @dev Gets remaining round length progress.
    /// @return remainingRoundLength Remaining round length.
    /// @return extendedRoundTime extended round time, if round length was reached.
    function getRemainingRoundLength() public view returns (uint256 remainingRoundLength, uint256 extendedRoundTime) {
        uint256 curRound = currentRound;
        uint256 blocksSinceRoundEnd = block.number - roundPoints[curRound - 1].endBlock;

        uint256 curRoundLength = roundPoints[curRound].length;
        if (blocksSinceRoundEnd > curRoundLength) {
            extendedRoundTime = blocksSinceRoundEnd - curRoundLength;
        } else {
            remainingRoundLength = curRoundLength - blocksSinceRoundEnd;
        }
    }

    /// @dev Gets round progress.
    /// @return Round progress.
    function getRoundProgress() external view returns (uint256) {
        uint256 curRound = currentRound;
        uint256 blocksSinceRoundEnd = block.number - roundPoints[curRound - 1].endBlock;

        uint256 curRoundLength = roundPoints[curRound].length;
        if (blocksSinceRoundEnd > curRoundLength) {
            blocksSinceRoundEnd = curRoundLength;
        }

        return (blocksSinceRoundEnd * 100) / curRoundLength;
    }

    /// @dev Gets total unclaimed rewards.
    /// @return Total unclaimed rewards.
    function getTotalUnclaimed() external view returns (uint256) {
        uint256 claimRound = currentRound - 1;
        return roundPoints[claimRound].availableRewards - roundPoints[claimRound].totalClaimed;
    }

    /// @param user User address.
    /// @return state game state.
    function getGameState(address user) external view returns (GameState memory state) {
        uint256 curRound = currentRound;
        RoundPoint storage ep = roundPoints[curRound];

        state.roundLength = ep.length;
        state.currentRound = curRound;
        state.minimumDonation = ep.minDonation;
        state.roundRewards = ep.availableRewards;
        state.totalDonated = ep.totalDonated;
        state.totalClaimed = ep.totalClaimed;

        uint256 roundStart = roundPoints[curRound - 1].endBlock;
        state.roundEndBlock = roundStart + ep.length;

        if (block.number < state.roundEndBlock) {
            state.blocksRemaining = state.roundEndBlock - block.number;
        }

        state.incentiveBalance = IToken(incentiveTokenAddress).balanceOf(address(this));
        state.userCurrentDonation = roundToDonations[curRound][user];

        if (state.totalDonated > 0 && state.userCurrentDonation > 0) {
            state.userCurrentShare = (state.userCurrentDonation * 1e18) / state.totalDonated;
        }

        uint256 claimRound = curRound - 1;
        state.hasClaimed = roundToClaimed[claimRound][user] > 0;

        if (roundPoints[claimRound].endBlock > 0) {
            uint256 donation = roundToDonations[claimRound][user];
            uint256 totalDon = roundPoints[claimRound].totalDonated;
            if (donation > 0 && totalDon > 0) {
                state.userClaimable = (donation * roundPoints[claimRound].availableRewards) / totalDon;
            }
        }

        state.canPlayGame = (
            state.userCurrentDonation == 0 && state.incentiveBalance >= state.roundRewards
                && block.number < state.roundEndBlock
        );
    }

    /// @dev Gets service multisig nonces.
    /// @param multisig Service multisig address.
    /// @return nonces Current donations value.
    function getMultisigNonces(address multisig) external view virtual returns (uint256[] memory nonces) {
        nonces = new uint256[](1);
        nonces[0] = epochDonationActivities[multisig];
    }

    /// @dev Checks if the service multisig liveness ratio passes the defined liveness threshold.
    /// @notice The ratio pass is true if there was a difference in donations between previous and current checkpoints.
    /// @param curNonces Current service multisig set of a single nonce.
    /// @param lastNonces Last service multisig set of a single nonce.
    /// @return ratioPass True, if the liveness ratio passes the check.
    function isRatioPass(uint256[] memory curNonces, uint256[] memory lastNonces, uint256)
        external
        view
        virtual
        returns (bool ratioPass)
    {
        if (curNonces[0] > lastNonces[0]) {
            ratioPass = true;
        }
    }

    /// @dev Receive function.
    receive() external payable {}
}
