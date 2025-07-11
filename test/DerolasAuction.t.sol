// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "lib/forge-std/src/Test.sol";
import {DerolasAuction, GameState} from "src/DerolasAuction.sol";
import {IToken} from "src/interfaces/IToken.sol";

contract TestDerolasAuctionContract is Test {
    DerolasAuction public c;

    // setup parameters
    uint256 public minimumDonation = 1000000000000000;
    address public balancerRouter = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address public poolId = 0xaF5B7999F491C42C05B5a2CA80f1d200D617cC8c;
    uint256 public assetsInPool = 8;
    address public incentiveTokenAddress = 0x54330d28ca3357F294334BDC454a032e7f353416; // OLAS
    uint256 public incentiveTokenIndex = 3;
    uint256 public availableRewards = 1e18;
    uint256 public roundLength = 90; // blocks

    // Test parameters
    address public whaleAddress = 0xC8F7030a4e25585624e2Fc792255a547255Cd77c;
    uint256 topUpAmount = 2e18; // 2 Incentive Token

    function setUp() public {
        c = new DerolasAuction(
            minimumDonation,
            balancerRouter,
            poolId,
            assetsInPool,
            incentiveTokenAddress,
            incentiveTokenIndex,
            availableRewards,
            roundLength
        );
    }

    function testGetGameState() public view {
        // Check that the game state is initialized correctly
        address owner = address(this);
        GameState memory gameState = c.getGameState(owner);
        assertEq(gameState.minimumDonation, minimumDonation, "Min donation should match");
        assertEq(gameState.incentiveBalance, 0, "Incentive balance should be zero initially");
    }

    function testDonateFailsWithoutIncentives() public {
        // Simulate a failing donation
        vm.expectRevert("Not enough rewards to play the game");
        c.donate{value: minimumDonation}();
    }

    function testTopupIncentivesBalance() public {
        // Check that the incentives can be topped up we impersonate a user who tops up the incentives
        vm.startPrank(whaleAddress);
        IToken(incentiveTokenAddress).approve(address(c), topUpAmount); // Approve 1 OLAS
        c.topUpIncentiveBalance(topUpAmount);

        // Verify the incentives were topped up
        GameState memory gameState = c.getGameState(whaleAddress);
        assertEq(gameState.incentiveBalance, topUpAmount, "Available rewards should match after top-up");
    }

    function testGetTotalUnclaimed() public view {
        // Check that the total unclaimed incentives are zero initially
        uint256 totalUnclaimed = c.getTotalUnclaimed();
        assertEq(totalUnclaimed, 0, "Total unclaimed incentives should be zero initially");
    }

    function testGetRoundProgress() public {
        // Check that the round progress is zero initially
        uint256 roundProgress = c.getRoundProgress();
        assertEq(roundProgress, 0, "Round progress should be zero initially");
        // we fast-forward to 1 block after the round length
        vm.roll(block.number + roundLength + 1);
        roundProgress = c.getRoundProgress();
        assertEq(roundProgress, 100, "Round progress should be 100% after round end");
    }

    function testGetRemainingRoundLength() public {
        // Check that the remaining round length is equal to the round length initially
        uint256 remainingRoundLength = c.getRemainingRoundLength();
        assertEq(remainingRoundLength, roundLength, "Remaining round length should match initial round length");
        // we fastforward to 1 block after the round length
        vm.roll(block.number + roundLength + 1);
        remainingRoundLength = c.getRemainingRoundLength();
        assertEq(remainingRoundLength, 0, "Remaining round length should be zero after round end");
    }

    function testGetBlocksSinceRoundEnd() public view {
        // Check that the seconds since round end is zero initially
        uint256 secondsSinceRoundEnd = c.getBlocksSinceRoundEnd();
        assertEq(secondsSinceRoundEnd, 0, "Blocks since round end should be zero initially");
    }

    function testGetCurrentShare() public view {
        // Check that the current share is zero initially
        uint256 currentShare = c.getCurrentShare(address(this));
        assertEq(currentShare, 0, "Current share should be zero initially");
    }

    function testEstimateTicketPercentage() public {
        // Check that the estimated ticket percentage from a donation works correctly
        this.testTopupIncentivesBalance(); // Ensure incentives are topped up
        uint256 initialEstimatedPercentage = c.estimateTicketPercentage(minimumDonation);
        assertEq(initialEstimatedPercentage, 1e18, "Estimated ticket percentage should be 100% as no donations yet");
        c.donate{value: minimumDonation}();
        uint256 finalEstimatedPercentage = c.estimateTicketPercentage(minimumDonation);
        assertEq(
            finalEstimatedPercentage,
            initialEstimatedPercentage / 2,
            "Estimated ticket percentage should decrease after donation"
        );
    }

    function testClaimable() public view {
        // Check that the claimable incentives are zero initially
        uint256 claimableIncentives = c.claimable(address(this));
        assertEq(claimableIncentives, 0, "Claimable incentives should be zero initially");
    }

    function testDonateWithIncentives() public {
        // Simulate a successful donation after topping up incentives
        this.testTopupIncentivesBalance(); // Ensure incentives are topped up
        GameState memory gameState = c.getGameState(whaleAddress);
        assertEq(gameState.totalDonated, 0, "Initial total donated should be zero");
        c.donate{value: minimumDonation}();
        // Verify the donation was successful
        gameState = c.getGameState(whaleAddress);
        assertEq(gameState.totalDonated, minimumDonation, "Total donated should match");
        assertEq(c.getCurrentShare(address(this)), 1e18, "Current share should be 100% after donation");
    }

    function testCanEndRound() public {
        // Check that the round can be ended after a donation
        // fast-forward to the block after the round length
        GameState memory firstGameState = c.getGameState(whaleAddress);
        vm.roll(block.number + roundLength + 1);
        c.endRound();
        GameState memory secondGameState = c.getGameState(whaleAddress);
        assertEq(
            secondGameState.currentRound,
            firstGameState.currentRound + 1,
            "Epoch should increment after ending the round"
        );
    }

    function testDonorCanClaim() public {
        // Check that the round cannot be ended without donations
        uint256 initialBalance = IToken(incentiveTokenAddress).balanceOf(address(this));
        assertTrue(initialBalance == 0, "Initial balance should be zero before claiming");
        this.testDonateWithIncentives(); // Ensure a donation has been made
        this.testCanEndRound(); // Ensure the round can be ended
        assertEq(
            c.claimable(address(this)),
            availableRewards,
            "Claimable incentives should be greater than zero after donation"
        );
        c.claim();
        uint256 finalBalance = IToken(incentiveTokenAddress).balanceOf(address(this));
        assertEq(finalBalance, availableRewards, "Final balance should be equal to available rewards after claiming");
        assertEq(c.claimable(address(this)), 0, "Claimable incentives should be zero after claiming");
    }

    function testChangeOwner() public {
        // Check that the owner can be changed
        address newOwner = address(0x123);
        c.changeOwner(newOwner);
        assertEq(c.owner(), newOwner, "Owner should be changed to the new address");
    }

    function testChangeParams() public {
        // Check that the parameters can be changed
        uint256 newMinimumDonation = 2000000000000000; // 2 wei
        uint256 newAvailableRewards = 2e18; // 2 Incentive Tokens
        uint256 newRoundLength = 120; // blocks

        c.changeParams(newAvailableRewards, newRoundLength, newMinimumDonation);

        this.testCanEndRound(); // Ensure the round can be ended after changing parameters
        GameState memory gameState = c.getGameState(address(this));
        assertEq(gameState.minimumDonation, newMinimumDonation, "Minimum donation should be updated");
    }

    // tests for activity of multisig nonces
    function testGetMultiSigNonces() public view {
        // Check that the multisig nonces are initialized correctly
        uint256[] memory nonce = c.getMultisigNonces(address(this));
        assertEq(nonce[0], 0, "Nonce should be zero initially");
    }

    function testMultiSigNonceIncrements() public {
        // Check that the multisig nonce increments correctly
        uint256[] memory initialNonce = c.getMultisigNonces(address(this));
        assertFalse(c.isRatioPass(initialNonce, initialNonce, 0), "isRatioPass should return false before increment");
        this.testDonorCanClaim(); // Ensure a donation has been made to trigger nonce increment
        uint256[] memory updatedNonce = c.getMultisigNonces(address(this));
        assertEq(updatedNonce[0], initialNonce[0] + minimumDonation, "Nonce should increment by 1");
        assertTrue(c.isRatioPass(updatedNonce, initialNonce, 0), "isRatioPass should return true after increment");
    }
}
