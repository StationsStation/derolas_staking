pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/DerolasAuction.sol";

contract TestContract is Test {
    DerolasAuction c;

    uint256 public minDonation = 1000000000000000;
    address public balancerRouter = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address public poolId = 0xaF5B7999F491C42C05B5a2CA80f1d200D617cC8c;
    uint256 public assetsInPool = 8;
    address public incentiveTokenAddress = 0x54330d28ca3357F294334BDC454a032e7f353416; // OLAS
    uint256 public incentiveTokenIndex = 3;
    uint256 public availableRewards = 1e18;
    uint256 public epochLength = 90; // blocks
    uint256 public maxCheckpointDelay = 10; // blocks

    function setUp() public {
        c = new DerolasAuction(
            minDonation,
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

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }
}
