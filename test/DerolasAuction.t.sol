// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "lib/forge-std/src/Test.sol";
import {DerolasAuction, GameState} from "src/DerolasAuction.sol";
import {IToken} from "src/interfaces/IToken.sol";
import {IBalancerVaultAdmin} from "src/interfaces/IBalancerVaultAdmin.sol";

contract TestDerolasAuctionContract is Test {
    DerolasAuction public c;

    // setup parameters
    uint256 public minimumDonation = 1000000000000000;
    address public balancerRouter = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address public balancerVaultAdmin = 0x35fFB749B273bEb20F40f35EdeB805012C539864; // Balancer Vault Admin
    address public poolId = 0xaF5B7999F491C42C05B5a2CA80f1d200D617cC8c;
    uint256 public assetsInPool = 8;
    address public incentiveTokenAddress = 0x54330d28ca3357F294334BDC454a032e7f353416; // OLAS
    uint256 public incentiveTokenIndex = 3;
    uint256 public wethIndex = 1; // WETH index in the pool
    uint256 public availableRewards = 1e18;
    uint256 public roundLength = 90; // blocks

    // Test parameters
    address public whaleAddress = 0xC8F7030a4e25585624e2Fc792255a547255Cd77c;
    uint256 public topUpAmount = 2e18; // 2 Incentive Token
    address public wethAddress = 0x4200000000000000000000000000000000000006; // WETH address on Base

    function setUp() public {
        c = new DerolasAuction(
            minimumDonation,
            balancerRouter,
            balancerVaultAdmin,
            poolId,
            assetsInPool,
            incentiveTokenAddress,
            incentiveTokenIndex,
            wethIndex,
            availableRewards,
            roundLength
        );
    }

    function testGetGameState() public view {
        // Check that the game state is initialized correctly
        address owner = address(this);
        GameState memory gameState = c.getGameState(owner);
        assertEq(gameState.minimumDonation, minimumDonation, "Min donation should match");
    }

    function testDonateFailsWithoutIncentives() public {
        // Simulate a failing donation
        vm.expectRevert("Not enough rewards to play the game");
        c.donate{value: minimumDonation}();
    }

    function testTopupIncentivesBalance() public {
        // Check that the incentives can be topped up we impersonate a user who tops up the incentives
        vm.startPrank(whaleAddress);
        GameState memory initialGameState = c.getGameState(whaleAddress);
        IToken(incentiveTokenAddress).approve(address(c), topUpAmount); // Approve 1 OLAS
        c.topUpIncentiveBalance(topUpAmount);

        // Verify the incentives were topped up
        GameState memory gameState = c.getGameState(whaleAddress);
        assertEq(
            gameState.incentiveBalance,
            initialGameState.incentiveBalance + topUpAmount,
            "Available rewards should match after top-up"
        );
        vm.stopPrank();
    }

    function testCannotTopupZeroIncentives() public {
        // Check that topping up zero incentives fails
        vm.expectRevert("Amount must be greater than 0");
        c.topUpIncentiveBalance(0);
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

    function testCannotEstimateTicketPercentageWithoutIncentives() public {
        // Check that estimating ticket percentage fails without incentives
        vm.expectRevert("Not enough rewards to play the game");
        c.estimateTicketPercentage(minimumDonation);
    }

    function testCannotEstimateTicketPercentageWithLessThanMinimumDonation() public {
        // Check that estimating ticket percentage fails with less than minimum donation
        vm.expectRevert("Minimum donation not met");
        c.estimateTicketPercentage(minimumDonation - 1);
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

    function testCannotDonateLessThanMinimum() public {
        // Check that a donation less than the minimum fails
        vm.expectRevert("Donation amount is less than the minimum donation");
        c.donate{value: minimumDonation - 1}();
    }

    function testCannotDonateTwiceInSameRound() public {
        // Check that a user cannot donate twice in the same round
        this.testDonateWithIncentives(); // Ensure a donation has been made
        vm.expectRevert("Already donated this round");
        c.donate{value: minimumDonation}(); // Attempt to donate again
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

    function testImportantParamsCarriedOver() public {
        // Check that important parameters are carried over to the next round
        GameState memory gameState = c.getGameState(address(this));
        assertEq(gameState.roundRewards, availableRewards, "Available rewards should match");
        assertEq(gameState.roundLength, roundLength, "Round length should match");
        assertEq(gameState.minimumDonation, minimumDonation, "Minimum donation should match");
        testCanEndRound();
        GameState memory nextGameState = c.getGameState(address(this));
        assertEq(nextGameState.roundRewards, gameState.roundRewards, "Available rewards should be carried over");
        assertEq(nextGameState.roundLength, gameState.roundLength, "Round length should be carried over");
        assertEq(nextGameState.minimumDonation, gameState.minimumDonation, "Minimum donation should be carried over");
    }

    function testCannotEndRoundEarly() public {
        // Check that the round cannot be ended early
        vm.expectRevert("Round not over");
        c.endRound();
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

    function testCannotClaimWithoutDonation() public {
        // Check that a user cannot claim incentives without making a donation
        vm.expectRevert("No donation found");
        c.claim();
    }

    function testCannotClaimTwice() public {
        // Check that a user cannot claim incentives before the round ends
        this.testDonateWithIncentives(); // Ensure a donation has been made
        this.testCanEndRound();
        c.claim();
        vm.expectRevert("Already claimed");
        c.claim(); // Attempt to claim again
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

    // Balancer donation tests.
    function testBalancerEthDonation() public {
        // Check that a donation can be made using Balancer's ETH donation method
        this.testTopupIncentivesBalance(); // Ensure incentives are topped up
        this.testDonateWithIncentives(); // Ensure a donation has been made
        IBalancerVaultAdmin balancerVaultAdminContract = IBalancerVaultAdmin(balancerVaultAdmin);
        uint256 initialBalance = IToken(wethAddress).balanceOf(balancerVaultAdminContract.vault());
        this.testCanEndRound(); // Ensure the round can be ended
        uint256 finalBalance = IToken(wethAddress).balanceOf(balancerVaultAdminContract.vault());
        assertEq(
            finalBalance,
            initialBalance + minimumDonation,
            "Final balance should be greater than initial balance after donation"
        );
    }

    function testBalancerUnclaimedIncentiveDonation() public {
        // Check that a donation can be made using Balancer's ETH donation method
        IBalancerVaultAdmin balancerVaultAdminContract = IBalancerVaultAdmin(balancerVaultAdmin);
        uint256 initialBalance = IToken(incentiveTokenAddress).balanceOf(balancerVaultAdminContract.vault());
        this.testTopupIncentivesBalance(); // Ensure incentives are topped up
        this.testDonateWithIncentives(); // Ensure a donation has been made
        this.testCanEndRound(); // Ensure the round can be ended
        uint256 secondBalance = IToken(incentiveTokenAddress).balanceOf(balancerVaultAdminContract.vault());
        assertEq(secondBalance, initialBalance, "Vault balance equal to initial balance after 1st round");
        this.testCanEndRound(); // Ensure the round can be ended again
        uint256 finalBalance = IToken(incentiveTokenAddress).balanceOf(balancerVaultAdminContract.vault());
        assertEq(finalBalance, initialBalance + availableRewards, "Final balance should include unclaimed");
    }

    // admin tests
    function testCanChangeOwner() public {
        // Check that the owner can change the contract owner
        address newOwner = address(0x123);
        c.changeOwner(newOwner);
        assertEq(c.owner(), newOwner, "Owner should be changed to the new address");
    }

    function testCannotChangeOwnerWithoutPermission() public {
        // Check that a non-owner cannot change the contract owner
        this.testCanChangeOwner(); // Ensure the owner is set
        vm.expectRevert("Unauthorized account");
        c.changeOwner(address(this)); // Change back to original owner
    }

    function testCannotChangeToZeroAddress() public {
        // Check that the owner cannot change the contract owner to zero address
        vm.expectRevert("Zero address");
        c.changeOwner(address(0));
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

    function testCannotChangeParamsWithoutPermission() public {
        // Check that a non-owner cannot change the contract parameters
        this.testCanChangeOwner(); // Ensure the owner is set
        vm.expectRevert("Unauthorized account");
        this.testChangeParams(); // Ensure parameters are set
    }

    function testCanWithdrawIncentiveBalance() public {
        // Check that the owner can withdraw incentives
        vm.expectRevert("No incentive token balance to withdraw");
        c.withdrawIncentiveTokenBalance();

        this.testTopupIncentivesBalance(); // Ensure incentives are topped up
        uint256 initialBalance = IToken(incentiveTokenAddress).balanceOf(address(this));
        assertEq(initialBalance, 0, "Initial balance should be zero before withdrawy");
        c.withdrawIncentiveTokenBalance();
        uint256 finalBalance = IToken(incentiveTokenAddress).balanceOf(address(this));
        assertGt(finalBalance, 0, "Final balance should be greater than zero after recovering incentives");
    }

    function testCannotWithdrawIncentiveBalanceWithoutPermission() public {
        // Check that a non-owner cannot withdraw incentives
        this.testTopupIncentivesBalance(); // Ensure incentives are topped up
        this.testCanChangeOwner(); // Ensure the owner is set
        vm.expectRevert("Unauthorized account");
        c.withdrawIncentiveTokenBalance(); // Attempt to withdraw incentives
    }

    // edge case tests
    function _multipleDonorsInSameRound(uint256 numDonors, uint256 nonce) public {
        // Check that multiple donors can donate in the same round
        for (uint256 i = 0; i < numDonors; i++) {
            address donor = address(uint160(uint256(keccak256(abi.encodePacked(i + nonce)))));
            vm.startPrank(donor);
            vm.deal(donor, minimumDonation); // Fund the donor with minimum donation
            assertEq(
                IToken(incentiveTokenAddress).balanceOf(donor), 0, "Donor should have zero incentive balance initially"
            );
            c.donate{value: minimumDonation}();
            vm.stopPrank();
        }
        this.testCanEndRound(); // Ensure the round can be ended after multiple donations
        // check that all donors now have claimable incentives
        for (uint256 i = 0; i < numDonors; i++) {
            address donor = address(uint160(uint256(keccak256(abi.encodePacked(i + nonce))))); // Recreate donor address
            // check that the current share is 1 / numDonors * 1e18
            assertEq(
                c.claimable(donor), availableRewards / numDonors, "Claimable incentives should be equal for all donors"
            );
            vm.startPrank(donor);
            c.claim();
            uint256 finalBalance = IToken(incentiveTokenAddress).balanceOf(donor);
            assertEq(
                finalBalance, availableRewards / numDonors, "Final balance should be equal to claimable incentives"
            );
            vm.stopPrank();
        }
    }

    function testMultipleDonorsInSameRound() public {
        // Test with 5 donors in the same round
        uint256 numDonors = 6; // Number of donors to simulate
        uint256 nonce = 0; // Nonce for unique donor addresses
        for (uint256 i = 0; i < numDonors; i++) {
            nonce = nonce + i;
            this.testTopupIncentivesBalance(); // Ensure incentives are topped up
            this._multipleDonorsInSameRound(i, nonce);
        }
    }

    function testHandlesBalancerEthDonationBelowTradeAmount() public {
        // test that end round does not fail when balance in eth is below the minimum trade amount
        // transfer some ETH to the contract
        uint256 minimumTradeAmount = IBalancerVaultAdmin(balancerVaultAdmin).getMinimumTradeAmount();
        vm.deal(address(c), minimumTradeAmount - 1); // 0.
        // Ensure the contract has less than the minimum trade amount in ETH
        assertLt(address(c).balance, minimumTradeAmount, "Contract should have less than minimum trade amount in ETH");
        this.testCanEndRound(); // Ensure the round can be ended without failing
    }
}
