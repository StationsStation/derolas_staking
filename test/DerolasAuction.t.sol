// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "lib/forge-std/src/Test.sol";
import {DerolasAuction, GameState} from "src/DerolasAuction.sol";
import {IToken} from "src/interfaces/IToken.sol";

contract TestDerolasAuctionContract is Test {
    DerolasAuction public c;

    uint256 public minimumDonation = 1000000000000000;
    address public balancerRouter = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address public poolId = 0xaF5B7999F491C42C05B5a2CA80f1d200D617cC8c;
    uint256 public assetsInPool = 8;
    address public incentiveTokenAddress = 0x54330d28ca3357F294334BDC454a032e7f353416; // OLAS
    uint256 public incentiveTokenIndex = 3;
    uint256 public availableRewards = 1e18;
    uint256 public epochLength = 90; // blocks
    uint256 public maxCheckpointDelay = 10; // blocks

    // olas whale address
    address public whaleAddress = 0xC8F7030a4e25585624e2Fc792255a547255Cd77c;

    function setUp() public {
        c = new DerolasAuction(
            minimumDonation,
            balancerRouter,
            poolId,
            assetsInPool,
            incentiveTokenAddress,
            incentiveTokenIndex,
            availableRewards,
            epochLength,
            maxCheckpointDelay
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
        IToken(incentiveTokenAddress).approve(address(c), 1e18); // Approve 1 OLAS
        uint256 topUpAmount = 1e18; // 1 OLAS
        c.topUpIncentiveBalance(topUpAmount);

        // Verify the incentives were topped up
        GameState memory gameState = c.getGameState(whaleAddress);
        assertEq(gameState.incentiveBalance, topUpAmount, "Available rewards should match after top-up");
    }
}
