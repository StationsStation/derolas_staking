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
    
    function addLiquidityProportional(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable returns (uint256[] memory amountsIn);
    
    function addLiquidityUnbalanced(
        address pool,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable returns (uint256 bptAmountOut);
    
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
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IBalancerVault {
    function getPoolTokens(bytes32 poolId) external view returns (
        address[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );
}

contract ConservativeProportionalLiquidity is Script {
    // Configuration - easily changeable parameters
    uint256 constant INITIAL_ETH_AMOUNT = 1 ether;
    uint256 constant FUNDING_AMOUNT = 10 ether;
    uint256 constant CONSERVATIVE_PERCENTAGE = 25; // 25% of each balance
    
    // Test account
    uint256 constant TEST_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant TEST_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    // Base mainnet addresses
    address constant ROUTER = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant DEROLAS_POOL = 0x7b4c560f33A71A9f7a500aF3C4c65b46fBBafdB7;
    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    
    // Derolas pool tokens (all 8 tokens including LBTC)
    address constant WEETH = 0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A;
    address constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address constant OLAS = 0x54330d28ca3357F294334BDC454a032e7f353416;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant DRV = 0x9d0E8f5b25384C7310CB8C6aE32C8fbeb645d083;
    address constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1;
    
    // Token addresses array
    address[] public poolTokens;
    
    function run() external {
        vm.startBroadcast(TEST_PRIVATE_KEY);
        
        console.log("=== CONSERVATIVE PROPORTIONAL LIQUIDITY ADDITION ===");
        console.log("Strategy: Use 25% of each token balance, accept slippage for success");
        console.log("Test Account:", TEST_ACCOUNT);
        console.log("Initial ETH balance:", address(TEST_ACCOUNT).balance);
        
        // Initialize pool tokens array
        poolTokens = [WEETH, WETH, DAI, OLAS, USDC, DRV, CBBTC, LBTC];
        
        // Fund account
        vm.deal(TEST_ACCOUNT, FUNDING_AMOUNT);
        console.log("Funded account with", FUNDING_AMOUNT, "ETH");
        
        // Step 1: Execute multicall swaps to acquire all 8 tokens
        console.log("\n=== STEP 1: MULTICALL SWAPS TO ACQUIRE ALL 8 TOKENS ===");
        uint256[] memory acquiredAmounts = executeMulticallSwaps();
        
        // Step 2: Conservative proportional liquidity addition
        console.log("\n=== STEP 2: CONSERVATIVE PROPORTIONAL LIQUIDITY ADDITION ===");
        executeConservativeLiquidityAddition(acquiredAmounts);
        
        vm.stopBroadcast();
    }
    
    function executeMulticallSwaps() internal returns (uint256[] memory) {
        IRouter router = IRouter(ROUTER);
        IWETH weth = IWETH(WETH);
        
        // Convert ETH to WETH
        weth.deposit{value: INITIAL_ETH_AMOUNT}();
        console.log("Converted", INITIAL_ETH_AMOUNT, "ETH to WETH");
        
        // Approve Permit2 for all tokens
        approvePermit2ForAllTokens();
        
        // Calculate swap amounts (1/8th each for 7 swaps, keep 1/8th WETH)
        uint256 totalAmount = weth.balanceOf(TEST_ACCOUNT);
        uint256 swapAmount = totalAmount / 8;
        uint256 wethToKeep = swapAmount;
        
        console.log("Total WETH for swaps:", totalAmount);
        console.log("Amount per swap:", swapAmount);
        console.log("WETH to keep:", wethToKeep);
        
        // Prepare multicall data for 7 swaps
        bytes[] memory multicallData = new bytes[](7);
        uint256 deadline = block.timestamp + 3600;
        
        // Swap 1: WETH -> weETH
        multicallData[0] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            WEETH, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut (set to 1 for testing)
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        // Swap 2: WETH -> DAI
        multicallData[1] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            DAI, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        // Swap 3: WETH -> OLAS
        multicallData[2] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            OLAS, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        // Swap 4: WETH -> USDC
        multicallData[3] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            USDC, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        // Swap 5: WETH -> DRV
        multicallData[4] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            DRV, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        // Swap 6: WETH -> cbBTC
        multicallData[5] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            CBBTC, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        // Swap 7: WETH -> LBTC
        multicallData[6] = abi.encodeWithSelector(
            router.swapSingleTokenExactIn.selector,
            DEROLAS_POOL, // pool
            WETH, // tokenIn
            LBTC, // tokenOut
            swapAmount, // exactAmountIn
            1, // minAmountOut
            deadline, // deadline
            false, // wethIsEth
            "" // userData
        );
        
        console.log("Multicall data prepared for 7 swaps (all 8 tokens):");
        console.log("  Swap 1: WETH -> weETH");
        console.log("  Swap 2: WETH -> DAI");
        console.log("  Swap 3: WETH -> OLAS");
        console.log("  Swap 4: WETH -> USDC");
        console.log("  Swap 5: WETH -> DRV");
        console.log("  Swap 6: WETH -> cbBTC");
        console.log("  Swap 7: WETH -> LBTC");
        console.log("  WETH kept: 1/8th of total amount");
        console.log("Total multicall operations:", multicallData.length);
        
        // Execute multicall for 7 swaps
        uint256[] memory acquiredAmounts = new uint256[](8);
        
        try router.multicall(multicallData) returns (bytes[] memory results) {
            console.log("SUCCESS: 7 swaps executed successfully!");
            console.log("Number of results:", results.length);
            
            // Parse results and store acquired amounts
            for (uint i = 0; i < results.length; i++) {
                if (results[i].length > 0) {
                    uint256 amountOut = abi.decode(results[i], (uint256));
                    acquiredAmounts[i] = amountOut;
                    console.log("Swap", i + 1, "amount out:", amountOut);
                } else {
                    console.log("Swap", i + 1, "result: empty");
                }
            }
            
            // Set WETH amount (kept from original)
            acquiredAmounts[1] = wethToKeep;
            console.log("WETH kept:", wethToKeep);
            
            console.log("\n=== Acquired Token Amounts ===");
            console.log("weETH:", acquiredAmounts[0]);
            console.log("WETH:", acquiredAmounts[1]);
            console.log("DAI:", acquiredAmounts[2]);
            console.log("OLAS:", acquiredAmounts[3]);
            console.log("USDC:", acquiredAmounts[4]);
            console.log("DRV:", acquiredAmounts[5]);
            console.log("cbBTC:", acquiredAmounts[6]);
            console.log("LBTC:", acquiredAmounts[7]);
            
        } catch Error(string memory reason) {
            console.log("ERROR: 7 swaps failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("ERROR: 7 swaps failed with low level error:");
            console.logBytes(lowLevelData);
        }
        
        return acquiredAmounts;
    }
    
    function executeConservativeLiquidityAddition(uint256[] memory acquiredAmounts) internal {
        console.log("\n=== CONSERVATIVE PROPORTIONAL LIQUIDITY ADDITION ===");
        console.log("Strategy: Use 25% of each token balance, accept slippage for success");
        
        // Get current token balances after swaps
        uint256[] memory currentBalances = new uint256[](8);
        currentBalances[0] = IERC20(WEETH).balanceOf(TEST_ACCOUNT);
        currentBalances[1] = IERC20(WETH).balanceOf(TEST_ACCOUNT);
        currentBalances[2] = IERC20(DAI).balanceOf(TEST_ACCOUNT);
        currentBalances[3] = IERC20(OLAS).balanceOf(TEST_ACCOUNT);
        currentBalances[4] = IERC20(USDC).balanceOf(TEST_ACCOUNT);
        currentBalances[5] = IERC20(DRV).balanceOf(TEST_ACCOUNT);
        currentBalances[6] = IERC20(CBBTC).balanceOf(TEST_ACCOUNT);
        currentBalances[7] = IERC20(LBTC).balanceOf(TEST_ACCOUNT);
        
        console.log("\n=== CURRENT TOKEN BALANCES ===");
        console.log("weETH:", currentBalances[0]);
        console.log("WETH:", currentBalances[1]);
        console.log("DAI:", currentBalances[2]);
        console.log("OLAS:", currentBalances[3]);
        console.log("USDC:", currentBalances[4]);
        console.log("DRV:", currentBalances[5]);
        console.log("cbBTC:", currentBalances[6]);
        console.log("LBTC:", currentBalances[7]);
        
        // Use actual token balances as maxAmountsIn to avoid AmountInAboveMax errors
        // This lets the pool calculate the actual amounts to add
        console.log("\n=== USING ACTUAL TOKEN BALANCES AS MAX AMOUNTS ===");
        console.log("Strategy: Use actual balances, let pool calculate amounts");
        
        // Use actual token balances as maxAmountsIn
        uint256[] memory maxAmountsIn = currentBalances;
        
        // Set very low exactBptAmountOut to be conservative
        uint256 exactBptAmountOut = 1; // Very conservative - just 1 wei
        
        console.log("Using actual token balances as maxAmountsIn:");
        console.log("weETH:", maxAmountsIn[0]);
        console.log("WETH:", maxAmountsIn[1]);
        console.log("DAI:", maxAmountsIn[2]);
        console.log("OLAS:", maxAmountsIn[3]);
        console.log("USDC:", maxAmountsIn[4]);
        console.log("DRV:", maxAmountsIn[5]);
        console.log("cbBTC:", maxAmountsIn[6]);
        console.log("LBTC:", maxAmountsIn[7]);
        console.log("exactBptAmountOut:", exactBptAmountOut, "(very conservative)");
        
        // Execute conservative proportional liquidity addition
        IRouter router = IRouter(ROUTER);
        
        try router.addLiquidityProportional(
            DEROLAS_POOL,
            maxAmountsIn,
            exactBptAmountOut,
            false, // wethIsEth
            "" // userData
        ) returns (uint256[] memory amountsIn) {
            console.log("SUCCESS: Conservative proportional liquidity addition executed!");
            console.log("Actual amounts used:");
            for (uint i = 0; i < amountsIn.length; i++) {
                console.log("Token", i, ":", amountsIn[i]);
            }
            
            // Check final balances
            console.log("\n=== FINAL TOKEN BALANCES ===");
            console.log("weETH:", IERC20(WEETH).balanceOf(TEST_ACCOUNT));
            console.log("WETH:", IERC20(WETH).balanceOf(TEST_ACCOUNT));
            console.log("DAI:", IERC20(DAI).balanceOf(TEST_ACCOUNT));
            console.log("OLAS:", IERC20(OLAS).balanceOf(TEST_ACCOUNT));
            console.log("USDC:", IERC20(USDC).balanceOf(TEST_ACCOUNT));
            console.log("DRV:", IERC20(DRV).balanceOf(TEST_ACCOUNT));
            console.log("cbBTC:", IERC20(CBBTC).balanceOf(TEST_ACCOUNT));
            console.log("LBTC:", IERC20(LBTC).balanceOf(TEST_ACCOUNT));
            
        } catch Error(string memory reason) {
            console.log("ERROR: Conservative liquidity addition failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("ERROR: Conservative liquidity addition failed with low level error:");
            console.logBytes(lowLevelData);
        }
    }
    
    function calculateConservativeAmounts(uint256[] memory balances) internal pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](8);
        
        for (uint i = 0; i < 8; i++) {
            // Use 25% of each balance
            amounts[i] = balances[i] / 4;
            
            // Ensure minimum amount of 1 wei
            if (amounts[i] == 0 && balances[i] > 0) {
                amounts[i] = 1;
            }
        }
        
        return amounts;
    }
    
    function approvePermit2ForAllTokens() internal {
        IPermit2 permit2 = IPermit2(PERMIT2);
        uint48 expiration = uint48(block.timestamp + 3600);
        
        // Approve Permit2 for all pool tokens
        for (uint i = 0; i < poolTokens.length; i++) {
            address token = poolTokens[i];
            uint160 maxAmount = type(uint160).max;
            
            try permit2.approve(token, ROUTER, maxAmount, expiration) {
                console.log("Approved Permit2 for", token);
            } catch Error(string memory reason) {
                console.log("Failed to approve Permit2 for", token, "reason:", reason);
            } catch (bytes memory lowLevelData) {
                console.log("Failed to approve Permit2 for", token, "low level error:");
                console.logBytes(lowLevelData);
            }
        }
    }
} 