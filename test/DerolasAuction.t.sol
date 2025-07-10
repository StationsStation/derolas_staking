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
    uint256 topUpAmount = 1e18; // 1 Incentive Token

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

    function testGetRoundProgress() public view {
        // Check that the round progress is zero initially
        uint256 roundProgress = c.getRoundProgress();
        assertEq(roundProgress, 0, "Round progress should be zero initially");
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
        uint256 estimatedPercentage = c.estimateTicketPercentage(minimumDonation);
        assertEq(estimatedPercentage, 1e18, "Estimated ticket percentage should be 100% as no donations exist yet");
    }

    function testClaimable() public view {
        // Check that the claimable incentives are zero initially
        uint256 claimableIncentives = c.claimable(address(this));
        assertEq(claimableIncentives, 0, "Claimable incentives should be zero initially");
    }

    function testDonateWithIncentives() public {
        // Simulate a successful donation after topping up incentives
        this.testTopupIncentivesBalance(); // Ensure incentives are topped up

        c.donate{value: minimumDonation}();
        // Verify the donation was successful
        GameState memory gameState = c.getGameState(whaleAddress);
        assertEq(gameState.totalDonated, minimumDonation, "Total donated should match");
    }
}
