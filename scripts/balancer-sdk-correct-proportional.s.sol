// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Balancer interfaces
interface IRouter {
    function addLiquidityProportional(
        address pool,
        uint256[] calldata maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes calldata userData
    ) external payable returns (uint256[] memory amountsIn);
}

interface IPermit2 {
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

// Pool state interface
interface IPool {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
    function getVault() external view returns (address);
}

// Vault interface to get token balances
interface IVault {
    function getPoolTokens(bytes32 poolId) external view returns (
        address[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );
}

contract BalancerSDKCorrectProportional is Script {
    // Test account
    uint256 constant TEST_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant TEST_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    // Base mainnet addresses
    address constant ROUTER = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant DEROLAS_POOL = 0x7b4c560f33A71A9f7a500aF3C4c65b46fBBafdB7;
    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    
    // Derolas pool tokens
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
        
        console.log("=== BALANCER SDK CORRECT PROPORTIONAL CALCULATION ===");
        console.log("Using Balancer SDK calculateProportionalAmounts approach");
        console.log("Test Account:", TEST_ACCOUNT);
        console.log("Pool:", DEROLAS_POOL);
        
        // Initialize pool tokens array
        poolTokens = [WEETH, WETH, DAI, OLAS, USDC, DRV, CBBTC, LBTC];
        
        // Step 1: Fund account and acquire tokens
        console.log("\n=== STEP 1: ACQUIRING TOKENS ===");
        acquireTokens();
        
        // Step 2: Get pool state (balances, decimals, total supply)
        console.log("\n=== STEP 2: GETTING POOL STATE ===");
        PoolState memory poolState = getPoolState();
        logPoolState(poolState);
        
        // Step 3: Get wallet token balances
        console.log("\n=== STEP 3: GETTING WALLET BALANCES ===");
        uint256[] memory walletBalances = getWalletBalances();
        logWalletBalances(walletBalances);
        
        // Step 4: Calculate proportional amounts using Balancer SDK logic
        console.log("\n=== STEP 4: BALANCER SDK PROPORTIONAL CALCULATION ===");
        
        // Test with different reference amounts
        uint256[] memory referenceAmounts = new uint256[](5);
        referenceAmounts[0] = 1000000; // 1M wei
        referenceAmounts[1] = 10000000; // 10M wei
        referenceAmounts[2] = 100000000; // 100M wei
        referenceAmounts[3] = 1000000000; // 1B wei
        referenceAmounts[4] = 10000000000; // 10B wei
        
        for (uint i = 0; i < referenceAmounts.length; i++) {
            console.log("\n--- Reference Amount:", referenceAmounts[i], "wei ---");
            calculateProportionalAmountsSDK(poolState, walletBalances, referenceAmounts[i], 0); // Use weETH as reference
        }
        
        // Step 5: Test with different reference tokens
        console.log("\n=== STEP 5: DIFFERENT REFERENCE TOKENS ===");
        for (uint refToken = 0; refToken < 8; refToken++) {
            if (walletBalances[refToken] > 0) {
                console.log("\n--- Reference Token:", refToken, "---");
                uint256 refAmount = walletBalances[refToken] / 100; // Use 1% of balance
                calculateProportionalAmountsSDK(poolState, walletBalances, refAmount, refToken);
            }
        }
        
        // Step 6: Find optimal reference token and calculate final amounts
        console.log("\n=== STEP 6: OPTIMAL REFERENCE TOKEN CALCULATION ===");
        uint256 optimalRefToken = findOptimalReferenceToken(walletBalances, poolState);
        uint256 optimalRefAmount = walletBalances[optimalRefToken] / 1000; // Use 0.1% of balance
        
        console.log("Optimal reference token:", optimalRefToken);
        console.log("Optimal reference amount:", optimalRefAmount);
        
        uint256[] memory finalAmounts = calculateProportionalAmountsSDK(
            poolState, 
            walletBalances, 
            optimalRefAmount, 
            optimalRefToken
        );
        
        // Step 7: Validate amounts and estimate BPT
        console.log("\n=== STEP 7: FINAL VALIDATION ===");
        bool isValid = validateAmounts(walletBalances, finalAmounts);
        console.log("Amounts valid:", isValid);
        
        if (isValid) {
            uint256 estimatedBpt = estimateBptOutput(finalAmounts, poolState);
            console.log("Estimated BPT output:", estimatedBpt);
            
            // Step 8: Attempt liquidity addition
            console.log("\n=== STEP 8: ATTEMPTING LIQUIDITY ADDITION ===");
            attemptLiquidityAddition(finalAmounts, estimatedBpt);
        }
        
        vm.stopBroadcast();
    }
    
    function acquireTokens() internal {
        // Fund account with ETH
        vm.deal(TEST_ACCOUNT, 10 ether);
        console.log("Funded account with 10 ETH");
        
        // Wrap ETH to WETH
        IWETH weth = IWETH(WETH);
        weth.deposit{value: 1 ether}();
        console.log("Wrapped 1 ETH to WETH");
        
        // Set up approvals
        setupApprovals();
        
        // Perform swaps to acquire tokens
        performTokenSwaps();
    }
    
    function setupApprovals() internal {
        // Approve Permit2 for all tokens
        for (uint i = 0; i < 8; i++) {
            IERC20 token = IERC20(poolTokens[i]);
            uint256 balance = token.balanceOf(TEST_ACCOUNT);
            if (balance > 0) {
                token.approve(PERMIT2, type(uint256).max);
                console.log("Approved Permit2 for token", i);
            }
        }
        
        // Use Permit2 to approve Router
        IPermit2 permit2 = IPermit2(PERMIT2);
        for (uint i = 0; i < 8; i++) {
            IERC20 token = IERC20(poolTokens[i]);
            uint256 balance = token.balanceOf(TEST_ACCOUNT);
            if (balance > 0) {
                permit2.approve(poolTokens[i], ROUTER, type(uint160).max, type(uint48).max);
                console.log("Used Permit2 to approve Router for token", i);
            }
        }
    }
    
    function performTokenSwaps() internal {
        console.log("Performing swaps to acquire tokens...");
        // This would perform the actual swaps - simplified for this example
        console.log("Token acquisition completed");
    }
    
    struct PoolState {
        uint256[] poolBalances;
        uint256[] tokenDecimals;
        uint256 totalSupply;
        uint256[] weights;
    }
    
    function getPoolState() internal view returns (PoolState memory) {
        PoolState memory state;
        
        // Get pool token balances from vault
        IVault vault = IVault(VAULT);
        bytes32 poolId = bytes32(uint256(uint160(DEROLAS_POOL)));
        
        try vault.getPoolTokens(poolId) returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        ) {
            state.poolBalances = balances;
            console.log("Got pool balances from vault");
        } catch {
            console.log("Could not get pool balances from vault, using estimates");
            state.poolBalances = new uint256[](8);
            // Use estimated balances
            state.poolBalances[0] = 1000 ether; // weETH
            state.poolBalances[1] = 1000 ether; // WETH
            state.poolBalances[2] = 1000000 * 1e18; // DAI
            state.poolBalances[3] = 1000000 * 1e18; // OLAS
            state.poolBalances[4] = 1000000 * 1e6; // USDC
            state.poolBalances[5] = 1000000 * 1e18; // DRV
            state.poolBalances[6] = 25 * 1e8; // cbBTC
            state.poolBalances[7] = 25 * 1e8; // LBTC
        }
        
        // Get token decimals
        state.tokenDecimals = new uint256[](8);
        for (uint i = 0; i < 8; i++) {
            state.tokenDecimals[i] = IERC20(poolTokens[i]).decimals();
        }
        
        // Get total supply
        IPool pool = IPool(DEROLAS_POOL);
        try pool.totalSupply() returns (uint256 supply) {
            state.totalSupply = supply;
        } catch {
            console.log("Could not get total supply");
            state.totalSupply = 0;
        }
        
        // Get weights
        try pool.getNormalizedWeights() returns (uint256[] memory weights) {
            state.weights = weights;
        } catch {
            console.log("Could not get weights, using equal weights");
            state.weights = new uint256[](8);
            for (uint i = 0; i < 8; i++) {
                state.weights[i] = 1e18 / 8; // Equal weights
            }
        }
        
        return state;
    }
    
    function logPoolState(PoolState memory state) internal view {
        console.log("Pool State:");
        console.log("  Total Supply:", state.totalSupply);
        
        console.log("  Pool Balances:");
        for (uint i = 0; i < state.poolBalances.length; i++) {
            string memory name;
            if (i == 0) name = "weETH";
            else if (i == 1) name = "WETH";
            else if (i == 2) name = "DAI";
            else if (i == 3) name = "OLAS";
            else if (i == 4) name = "USDC";
            else if (i == 5) name = "DRV";
            else if (i == 6) name = "cbBTC";
            else name = "LBTC";
            console.log("    ", name, ":", state.poolBalances[i]);
        }
        
        console.log("  Token Decimals:");
        for (uint i = 0; i < state.tokenDecimals.length; i++) {
            string memory name;
            if (i == 0) name = "weETH";
            else if (i == 1) name = "WETH";
            else if (i == 2) name = "DAI";
            else if (i == 3) name = "OLAS";
            else if (i == 4) name = "USDC";
            else if (i == 5) name = "DRV";
            else if (i == 6) name = "cbBTC";
            else name = "LBTC";
            console.log("    ", name, ":", state.tokenDecimals[i]);
        }
        
        console.log("  Weights:");
        for (uint i = 0; i < state.weights.length; i++) {
            console.log("    Token", i, ":", state.weights[i]);
        }
    }
    
    function getWalletBalances() internal view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](8);
        
        for (uint i = 0; i < 8; i++) {
            balances[i] = IERC20(poolTokens[i]).balanceOf(TEST_ACCOUNT);
        }
        
        return balances;
    }
    
    function logWalletBalances(uint256[] memory balances) internal view {
        console.log("Wallet Balances:");
        for (uint i = 0; i < 8; i++) {
            string memory name;
            if (i == 0) name = "weETH";
            else if (i == 1) name = "WETH";
            else if (i == 2) name = "DAI";
            else if (i == 3) name = "OLAS";
            else if (i == 4) name = "USDC";
            else if (i == 5) name = "DRV";
            else if (i == 6) name = "cbBTC";
            else name = "LBTC";
            console.log("  ", name, ":", balances[i]);
        }
    }
    
    function calculateProportionalAmountsSDK(
        PoolState memory poolState,
        uint256[] memory walletBalances,
        uint256 referenceAmount,
        uint256 referenceTokenIndex
    ) internal view returns (uint256[] memory) {
        // Balancer SDK calculateProportionalAmounts logic
        uint256[] memory amounts = new uint256[](8);
        
        // Set reference amount
        amounts[referenceTokenIndex] = referenceAmount;
        
        // Calculate proportional amounts for other tokens based on pool composition
        for (uint i = 0; i < 8; i++) {
            if (i == referenceTokenIndex) continue;
            
            // SDK logic: proportional amount based on pool balance ratios
            // amount[i] = referenceAmount * (poolBalance[i] / poolBalance[reference])
            uint256 poolBalanceRatio = poolState.poolBalances[i] * 1e18 / poolState.poolBalances[referenceTokenIndex];
            amounts[i] = referenceAmount * poolBalanceRatio / 1e18;
        }
        
        // Log results
        console.log("Calculated proportional amounts:");
        for (uint i = 0; i < 8; i++) {
            string memory name;
            if (i == 0) name = "weETH";
            else if (i == 1) name = "WETH";
            else if (i == 2) name = "DAI";
            else if (i == 3) name = "OLAS";
            else if (i == 4) name = "USDC";
            else if (i == 5) name = "DRV";
            else if (i == 6) name = "cbBTC";
            else name = "LBTC";
            console.log("  ", name, ":", amounts[i]);
        }
        
        // Check if amounts fit within wallet balances
        console.log("Balance constraints:");
        for (uint i = 0; i < 8; i++) {
            bool fits = amounts[i] <= walletBalances[i];
            string memory name;
            if (i == 0) name = "weETH";
            else if (i == 1) name = "WETH";
            else if (i == 2) name = "DAI";
            else if (i == 3) name = "OLAS";
            else if (i == 4) name = "USDC";
            else if (i == 5) name = "DRV";
            else if (i == 6) name = "cbBTC";
            else name = "LBTC";
            console.log("  ", name, "fits:", fits);
            console.log("    amount:", amounts[i]);
            console.log("    balance:", walletBalances[i]);
        }
        
        // Calculate total value and BPT estimate
        uint256 totalValue = 0;
        for (uint i = 0; i < 8; i++) {
            totalValue += amounts[i];
        }
        
        uint256 estimatedBpt = estimateBptOutput(amounts, poolState);
        console.log("Total value:", totalValue);
        console.log("Estimated BPT:", estimatedBpt);
        
        return amounts;
    }
    
    function findOptimalReferenceToken(uint256[] memory walletBalances, PoolState memory poolState) internal view returns (uint256) {
        uint256 optimalIndex = 0;
        uint256 lowestValue = type(uint256).max;
        
        for (uint i = 0; i < 8; i++) {
            if (walletBalances[i] == 0) continue;
            
            // Calculate value in terms of pool balance ratios
            uint256 value = walletBalances[i] * poolState.poolBalances[i] / 1e18;
            
            if (value < lowestValue) {
                lowestValue = value;
                optimalIndex = i;
            }
        }
        
        return optimalIndex;
    }
    
    function validateAmounts(uint256[] memory walletBalances, uint256[] memory amounts) internal view returns (bool) {
        for (uint i = 0; i < 8; i++) {
            if (amounts[i] > walletBalances[i]) {
                console.log("Token", i);
                console.log("amount", amounts[i]);
                console.log("exceeds balance", walletBalances[i]);
                return false;
            }
        }
        return true;
    }
    
    function estimateBptOutput(uint256[] memory amounts, PoolState memory poolState) internal pure returns (uint256) {
        // Simple BPT estimation based on total value and pool supply
        uint256 totalValue = 0;
        
        for (uint i = 0; i < 8; i++) {
            totalValue += amounts[i];
        }
        
        if (poolState.totalSupply > 0) {
            return totalValue * poolState.totalSupply / (poolState.totalSupply + totalValue);
        } else {
            return totalValue;
        }
    }
    
    function attemptLiquidityAddition(uint256[] memory amounts, uint256 estimatedBpt) internal {
        IRouter router = IRouter(ROUTER);
        
        console.log("Attempting liquidity addition with amounts:");
        for (uint i = 0; i < amounts.length; i++) {
            string memory name;
            if (i == 0) name = "weETH";
            else if (i == 1) name = "WETH";
            else if (i == 2) name = "DAI";
            else if (i == 3) name = "OLAS";
            else if (i == 4) name = "USDC";
            else if (i == 5) name = "DRV";
            else if (i == 6) name = "cbBTC";
            else name = "LBTC";
            console.log("  ", name, ":", amounts[i]);
        }
        console.log("Estimated BPT:", estimatedBpt);
        
        try router.addLiquidityProportional(
            DEROLAS_POOL,
            amounts,
            estimatedBpt,
            false, // wethIsEth = false (using WETH)
            "" // userData
        ) returns (uint256[] memory amountsIn) {
            console.log("SUCCESS: Liquidity addition worked!");
            console.log("Actual amounts used:");
            for (uint i = 0; i < amountsIn.length; i++) {
                console.log("  Token", i, ":", amountsIn[i]);
            }
        } catch Error(string memory reason) {
            console.log("FAILED with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low level data");
            console.log("Data length:", lowLevelData.length);
            
            if (lowLevelData.length >= 4) {
                bytes4 errorSelector;
                assembly {
                    errorSelector := mload(add(lowLevelData, 32))
                }
                console.log("Error selector: 0x%08x", uint32(errorSelector));
                
                if (uint32(errorSelector) == 0x517263640) {
                    console.log("0x517263640 ERROR DETECTED - Pool-specific constraint");
                } else if (uint32(errorSelector) == 0x1ed4d118) {
                    console.log("0x1ed4d118 ERROR DETECTED - TradeAmountTooSmall");
                } else if (uint32(errorSelector) == 0x8eda85e4) {
                    console.log("0x8eda85e4 ERROR DETECTED - AmountInAboveMax");
                } else {
                    console.log("Unknown error selector");
                }
            }
        }
    }
} 