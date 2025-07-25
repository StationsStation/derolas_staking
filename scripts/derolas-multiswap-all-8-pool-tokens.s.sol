// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Balancer interfaces - following working examples exactly
interface IRouter {
    function swapSingleTokenExactIn(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 exactAmountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bool wethIsEth,
        bytes memory userData
    ) external payable returns (uint256 amountOut);
    
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

interface IPermit2 {
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;
    
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract DerolasMultiswapAll8PoolTokens is Script {
    // Test account
    uint256 constant TEST_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant TEST_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    // Base mainnet addresses (from pool-operation-examples-v3 AddressRegistry)
    address constant ROUTER = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant DEROLAS_POOL = 0x7b4c560f33A71A9f7a500aF3C4c65b46fBBafdB7;
    
    // ALL Derolas pool tokens (including LBTC)
    address constant WEETH = 0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A;
    address constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address constant OLAS = 0x54330d28ca3357F294334BDC454a032e7f353416;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant DRV = 0x9d0E8f5b25384C7310CB8C6aE32C8fbeb645d083;
    address constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1; // INCLUDING LBTC
    
    function run() external {
        vm.startBroadcast(TEST_PRIVATE_KEY);
        
        console.log("=== Derolas Multiswap ALL 8 Pool Tokens (Including LBTC) ===");
        console.log("Test Account:", TEST_ACCOUNT);
        console.log("Initial ETH balance:", address(TEST_ACCOUNT).balance);
        
        // Fund account
        vm.deal(TEST_ACCOUNT, 10 ether);
        console.log("Funded with 10 ETH");
        
        // Wrap ETH to WETH (using same amount that worked before)
        IWETH weth = IWETH(WETH);
        uint256 wethAmount = 0.00008 ether; // Same amount that worked in previous atomic multiswap
        weth.deposit{value: wethAmount}();
        console.log("Wrapped", wethAmount, "ETH to WETH");
        console.log("WETH balance:", weth.balanceOf(TEST_ACCOUNT));
        
        // CORRECT PERMIT2 APPROVAL PATTERN (following working examples exactly)
        console.log("\n=== Setting up Permit2 approvals ===");
        
        // Step 1: Approve Permit2 to spend WETH (following working example exactly)
        weth.approve(PERMIT2, type(uint256).max);
        console.log("Approved Permit2 to spend WETH");
        
        // Step 2: Use Permit2 to approve Router (following working example exactly)
        IPermit2 permit2 = IPermit2(PERMIT2);
        permit2.approve(WETH, ROUTER, type(uint160).max, type(uint48).max);
        console.log("Used Permit2 to approve Router for WETH");
        
        // Test Multiswap ALL 8 Pool Tokens: 7 swaps to get 8 tokens with 1/8th each
        console.log("\n=== Testing Multiswap ALL 8 Pool Tokens ===");
        testMultiswapAll8PoolTokens(wethAmount);
        
        vm.stopBroadcast();
    }
    
    function testMultiswapAll8PoolTokens(uint256 totalWethAmount) internal {
        IWETH weth = IWETH(WETH);
        IERC20 weeth = IERC20(WEETH);
        IERC20 dai = IERC20(DAI);
        IERC20 olas = IERC20(OLAS);
        IERC20 usdc = IERC20(USDC);
        IERC20 drv = IERC20(DRV);
        IERC20 cbbtc = IERC20(CBBTC);
        IERC20 lbtc = IERC20(LBTC);
        IRouter router = IRouter(ROUTER);
        
        console.log("WETH balance before multiswap:", weth.balanceOf(TEST_ACCOUNT));
        console.log("weETH balance before multiswap:", weeth.balanceOf(TEST_ACCOUNT));
        console.log("DAI balance before multiswap:", dai.balanceOf(TEST_ACCOUNT));
        console.log("OLAS balance before multiswap:", olas.balanceOf(TEST_ACCOUNT));
        console.log("USDC balance before multiswap:", usdc.balanceOf(TEST_ACCOUNT));
        console.log("DRV balance before multiswap:", drv.balanceOf(TEST_ACCOUNT));
        console.log("cbBTC balance before multiswap:", cbbtc.balanceOf(TEST_ACCOUNT));
        console.log("LBTC balance before multiswap:", lbtc.balanceOf(TEST_ACCOUNT));
        
        // Calculate swap amounts: each swap uses 1/8th of total WETH (for 8 tokens total)
        uint256 swapAmount = totalWethAmount / 8; // 1/8th for each token
        uint256 deadline = block.timestamp + 3600; // 1 hour
        
        console.log("Total WETH amount:", totalWethAmount);
        console.log("Swap amount per token (1/8th):", swapAmount);
        console.log("Deadline:", deadline);
        
        // Prepare multicall data for 7 swaps to get 8 tokens with 1/8th each
        console.log("\n=== Preparing Multicall Data for ALL 8 Pool Tokens ===");
        bytes[] memory multicallData = new bytes[](7);
        
        // Strategy: 7 swaps for 7 different tokens, keep 1/8th WETH
        // This gives us 8 tokens total with 1/8th each
        
        // Swap 1: WETH → weETH (1/8th)
        multicallData[0] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            WEETH, // tokenOut
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        // Swap 2: WETH → DAI (1/8th)
        multicallData[1] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            DAI, // tokenOut
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        // Swap 3: WETH → OLAS (1/8th)
        multicallData[2] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            OLAS, // tokenOut
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        // Swap 4: WETH → USDC (1/8th)
        multicallData[3] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            USDC, // tokenOut
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        // Swap 5: WETH → DRV (1/8th)
        multicallData[4] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            DRV, // tokenOut
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        // Swap 6: WETH → cbBTC (1/8th)
        multicallData[5] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            CBBTC, // tokenOut
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        // Swap 7: WETH → LBTC (1/8th) - INCLUDING LBTC!
        multicallData[6] = abi.encodeWithSelector(
            IRouter.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            LBTC, // tokenOut (INCLUDING LBTC!)
            swapAmount, // exactAmountIn (1/8th)
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth (false since we're using WETH)
            "" // userData
        );
        
        console.log("Multicall data prepared for ALL 8 pool tokens:");
        console.log("  Swap 1: WETH -> weETH (1/8th), amount:", swapAmount);
        console.log("  Swap 2: WETH -> DAI (1/8th), amount:", swapAmount);
        console.log("  Swap 3: WETH -> OLAS (1/8th), amount:", swapAmount);
        console.log("  Swap 4: WETH -> USDC (1/8th), amount:", swapAmount);
        console.log("  Swap 5: WETH -> DRV (1/8th), amount:", swapAmount);
        console.log("  Swap 6: WETH -> cbBTC (1/8th), amount:", swapAmount);
        console.log("  Swap 7: WETH -> LBTC (1/8th), amount:", swapAmount);
        console.log("  Total multicall operations:", multicallData.length);
        console.log("  INCLUDING: LBTC (testing if multicall works with it)");
        console.log("  Expected result: ALL 8 pool tokens with 1/8th of initial value each");
        console.log("  Perfect for adding liquidity to proportional pool!");
        console.log("  Final token distribution:");
        console.log("    - weETH: 1/8th");
        console.log("    - DAI: 1/8th");
        console.log("    - OLAS: 1/8th");
        console.log("    - USDC: 1/8th");
        console.log("    - DRV: 1/8th");
        console.log("    - cbBTC: 1/8th");
        console.log("    - LBTC: 1/8th");
        console.log("    - WETH: 1/8th (kept)");
        console.log("    - Total: ALL 8 pool tokens with 1/8th each");
        
        // Execute multicall for ALL 8 pool tokens
        console.log("\n=== Executing Multiswap ALL 8 Pool Tokens ===");
        
        try router.multicall(multicallData) returns (bytes[] memory results) {
            console.log("SUCCESS: Multiswap ALL 8 pool tokens executed successfully!");
            console.log("Number of results:", results.length);
            
            // Parse results if available
            uint256 totalWeethOut = 0;
            uint256 totalDaiOut = 0;
            uint256 totalOlasOut = 0;
            uint256 totalUsdcOut = 0;
            uint256 totalDrvOut = 0;
            uint256 totalCbbtcOut = 0;
            uint256 totalLbtcOut = 0;
            uint256 wethKept = totalWethAmount - (swapAmount * 7); // Remaining WETH
            
            for (uint256 i = 0; i < results.length; i++) {
                if (results[i].length > 0) {
                    uint256 amountOut = abi.decode(results[i], (uint256));
                    if (i == 0) {
                        totalWeethOut = amountOut;
                        console.log("weETH swap amount out:", amountOut);
                    } else if (i == 1) {
                        totalDaiOut = amountOut;
                        console.log("DAI swap amount out:", amountOut);
                    } else if (i == 2) {
                        totalOlasOut = amountOut;
                        console.log("OLAS swap amount out:", amountOut);
                    } else if (i == 3) {
                        totalUsdcOut = amountOut;
                        console.log("USDC swap amount out:", amountOut);
                    } else if (i == 4) {
                        totalDrvOut = amountOut;
                        console.log("DRV swap amount out:", amountOut);
                    } else if (i == 5) {
                        totalCbbtcOut = amountOut;
                        console.log("cbBTC swap amount out:", amountOut);
                    } else if (i == 6) {
                        totalLbtcOut = amountOut;
                        console.log("LBTC swap amount out:", amountOut);
                    }
                }
            }
            
            console.log("\n=== Total Results (ALL 8 Pool Tokens with 1/8th Each) ===");
            console.log("Total weETH received (1/8th):", totalWeethOut);
            console.log("Total DAI received (1/8th):", totalDaiOut);
            console.log("Total OLAS received (1/8th):", totalOlasOut);
            console.log("Total USDC received (1/8th):", totalUsdcOut);
            console.log("Total DRV received (1/8th):", totalDrvOut);
            console.log("Total cbBTC received (1/8th):", totalCbbtcOut);
            console.log("Total LBTC received (1/8th):", totalLbtcOut);
            console.log("WETH kept (1/8th):", wethKept);
            console.log("Total WETH used in swaps:", swapAmount * 7);
            console.log("Total WETH kept:", wethKept);
            
            // Check final balances
            console.log("\n=== Final Balances (Ready for Pool Liquidity) ===");
            console.log("WETH balance after multiswap:", weth.balanceOf(TEST_ACCOUNT));
            console.log("weETH balance after multiswap:", weeth.balanceOf(TEST_ACCOUNT));
            console.log("DAI balance after multiswap:", dai.balanceOf(TEST_ACCOUNT));
            console.log("OLAS balance after multiswap:", olas.balanceOf(TEST_ACCOUNT));
            console.log("USDC balance after multiswap:", usdc.balanceOf(TEST_ACCOUNT));
            console.log("DRV balance after multiswap:", drv.balanceOf(TEST_ACCOUNT));
            console.log("cbBTC balance after multiswap:", cbbtc.balanceOf(TEST_ACCOUNT));
            console.log("LBTC balance after multiswap:", lbtc.balanceOf(TEST_ACCOUNT));
            
            // Verify success and confirm ALL 8 tokens with 1/8th each
            if (weeth.balanceOf(TEST_ACCOUNT) > 0 && 
                dai.balanceOf(TEST_ACCOUNT) > 0 && 
                olas.balanceOf(TEST_ACCOUNT) > 0 && 
                usdc.balanceOf(TEST_ACCOUNT) > 0 && 
                drv.balanceOf(TEST_ACCOUNT) > 0 && 
                cbbtc.balanceOf(TEST_ACCOUNT) > 0 &&
                lbtc.balanceOf(TEST_ACCOUNT) > 0 &&
                weth.balanceOf(TEST_ACCOUNT) > 0) {
                console.log("SUCCESS: Multiswap ALL 8 pool tokens completed successfully!");
                console.log("SUCCESS: All 7 swaps executed in single transaction!");
                console.log("SUCCESS: Each token has 1/8th of initial WETH value!");
                console.log("SUCCESS: ALL 8 pool tokens ready for proportional pool liquidity!");
                console.log("SUCCESS: weETH, DAI, OLAS, USDC, DRV, cbBTC, LBTC, WETH(keep)");
                console.log("SUCCESS: LBTC swap worked successfully!");
                console.log("SUCCESS: Perfect for adding liquidity to proportional pool!");
            } else {
                console.log("WARNING: Some swaps may have failed");
                if (lbtc.balanceOf(TEST_ACCOUNT) == 0) {
                    console.log("NOTE: LBTC swap may have failed due to liquidity issues");
                }
            }
            
        } catch Error(string memory reason) {
            console.log("FAILED: Multiswap ALL 8 pool tokens failed with reason:", reason);
            console.log("This may indicate LBTC liquidity issues or other problems");
        } catch {
            console.log("FAILED: Multiswap ALL 8 pool tokens failed with unknown error");
            console.log("This may indicate LBTC liquidity issues or other problems");
        }
    }
} 