// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IPool {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
    function getSwapFeePercentage() external view returns (uint256);
    function getTokenRates() external view returns (uint256[] memory);
}

contract BalancerSDKProportionalCalculation is Script {
    uint256 constant TEST_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant TEST_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    address constant DEROLAS_POOL = 0x7b4c560f33A71A9f7a500aF3C4c65b46fBBafdB7;
    
    // Token addresses
    address constant WEETH = 0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address constant OLAS = 0x54330d28ca3357F294334BDC454a032e7f353416;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant DRV = 0x9d0E8f5b25384C7310CB8C6aE32C8fbeb645d083;
    address constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1;
    
    function run() external view {
        console.log("=== BALANCER SDK PROPORTIONAL CALCULATION ===");
        
        // Step 1: Get current pool state
        console.log("\n=== STEP 1: POOL STATE ===");
        PoolState memory poolState = getPoolState();
        logPoolState(poolState);
        
        // Step 2: Get current token balances
        console.log("\n=== STEP 2: TOKEN BALANCES ===");
        uint256[] memory balances = getTokenBalances();
        logTokenBalances(balances);
        
        // Step 3: Calculate proportional amounts using Balancer SDK logic
        console.log("\n=== STEP 3: BALANCER SDK PROPORTIONAL CALCULATION ===");
        
        // Test with different reference amounts
        uint256[] memory referenceAmounts = new uint256[](5);
        referenceAmounts[0] = 1000000; // 1M wei
        referenceAmounts[1] = 10000000; // 10M wei  
        referenceAmounts[2] = 100000000; // 100M wei
        referenceAmounts[3] = 1000000000; // 1B wei
        referenceAmounts[4] = 10000000000; // 10B wei
        
        for (uint i = 0; i < referenceAmounts.length; i++) {
            console.log("\n--- Reference Amount:", referenceAmounts[i], "wei ---");
            calculateProportionalAmountsSDK(balances, poolState, referenceAmounts[i], 0); // Use weETH as reference
        }
        
        // Step 4: Test with different reference tokens
        console.log("\n=== STEP 4: DIFFERENT REFERENCE TOKENS ===");
        for (uint refToken = 0; refToken < 8; refToken++) {
            if (balances[refToken] > 0) {
                console.log("\n--- Reference Token:", refToken, "---");
                uint256 refAmount = balances[refToken] / 100; // Use 1% of balance
                calculateProportionalAmountsSDK(balances, poolState, refAmount, refToken);
            }
        }
        
        // Step 5: Analyze pool constraints
        console.log("\n=== STEP 5: POOL CONSTRAINT ANALYSIS ===");
        analyzePoolConstraints(poolState, balances);
    }
    
    struct PoolState {
        uint256[] weights;
        uint256 totalSupply;
        uint256 swapFee;
        uint256[] rates;
    }
    
    function getPoolState() internal view returns (PoolState memory) {
        IPool pool = IPool(DEROLAS_POOL);
        
        PoolState memory state;
        
        try pool.getNormalizedWeights() returns (uint256[] memory weights) {
            state.weights = weights;
        } catch {
            console.log("Could not get normalized weights, using equal weights");
            state.weights = new uint256[](8);
            for (uint i = 0; i < 8; i++) {
                state.weights[i] = 1e18 / 8; // Equal weights
            }
        }
        
        try pool.totalSupply() returns (uint256 supply) {
            state.totalSupply = supply;
        } catch {
            console.log("Could not get total supply");
            state.totalSupply = 0;
        }
        
        try pool.getSwapFeePercentage() returns (uint256 fee) {
            state.swapFee = fee;
        } catch {
            console.log("Could not get swap fee");
            state.swapFee = 0;
        }
        
        try pool.getTokenRates() returns (uint256[] memory rates) {
            state.rates = rates;
        } catch {
            console.log("Could not get token rates, using 1:1");
            state.rates = new uint256[](8);
            for (uint i = 0; i < 8; i++) {
                state.rates[i] = 1e18;
            }
        }
        
        return state;
    }
    
    function logPoolState(PoolState memory state) internal view {
        console.log("Pool State:");
        console.log("  Total Supply:", state.totalSupply);
        console.log("  Swap Fee:", state.swapFee);
        console.log("  Weights:");
        for (uint i = 0; i < state.weights.length; i++) {
            console.log("    Token", i, ":", state.weights[i]);
        }
        console.log("  Rates:");
        for (uint i = 0; i < state.rates.length; i++) {
            console.log("    Token", i, ":", state.rates[i]);
        }
    }
    
    function getTokenBalances() internal view returns (uint256[] memory) {
        address[] memory tokens = new address[](8);
        tokens[0] = WEETH;
        tokens[1] = WETH;
        tokens[2] = DAI;
        tokens[3] = OLAS;
        tokens[4] = USDC;
        tokens[5] = DRV;
        tokens[6] = CBBTC;
        tokens[7] = LBTC;
        
        uint256[] memory balances = new uint256[](8);
        for (uint i = 0; i < 8; i++) {
            balances[i] = IERC20(tokens[i]).balanceOf(TEST_ACCOUNT);
        }
        
        return balances;
    }
    
    function logTokenBalances(uint256[] memory balances) internal view {
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
        uint256[] memory balances,
        PoolState memory poolState,
        uint256 referenceAmount,
        uint256 referenceTokenIndex
    ) internal view {
        // Balancer SDK proportional calculation logic
        uint256[] memory amounts = new uint256[](8);
        
        // Set reference amount
        amounts[referenceTokenIndex] = referenceAmount;
        
        // Calculate proportional amounts for other tokens based on pool weights
        for (uint i = 0; i < 8; i++) {
            if (i == referenceTokenIndex) continue;
            
            // SDK logic: proportional amount = referenceAmount * (weight[i] / weight[reference])
            uint256 weightRatio = poolState.weights[i] * 1e18 / poolState.weights[referenceTokenIndex];
            amounts[i] = referenceAmount * weightRatio / 1e18;
        }
        
        // Log results
        console.log("Calculated amounts:");
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
        
        // Check if amounts fit within balances
        console.log("Balance constraints:");
        for (uint i = 0; i < 8; i++) {
            bool fits = amounts[i] <= balances[i];
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
            console.log("    balance:", balances[i]);
        }
        
        // Calculate total value and BPT estimate
        uint256 totalValue = 0;
        for (uint i = 0; i < 8; i++) {
            totalValue += amounts[i];
        }
        
        uint256 estimatedBpt = estimateBptOutput(amounts, poolState);
        console.log("Total value:", totalValue);
        console.log("Estimated BPT:", estimatedBpt);
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
    
    function analyzePoolConstraints(PoolState memory poolState, uint256[] memory balances) internal view {
        console.log("Pool Constraint Analysis:");
        
        // Calculate minimum viable amounts
        uint256 minBalance = type(uint256).max;
        uint256 minTokenIndex = 0;
        
        for (uint i = 0; i < 8; i++) {
            if (balances[i] > 0 && balances[i] < minBalance) {
                minBalance = balances[i];
                minTokenIndex = i;
            }
        }
        
        console.log("Minimum balance token:", minTokenIndex, "with balance:", minBalance);
        
        // Calculate what happens if we use 1% of minimum balance
        uint256 testAmount = minBalance / 100;
        console.log("Test amount (1% of min):", testAmount);
        
        // Calculate proportional amounts for this test amount
        uint256[] memory testAmounts = new uint256[](8);
        testAmounts[minTokenIndex] = testAmount;
        
        for (uint i = 0; i < 8; i++) {
            if (i == minTokenIndex) continue;
            
            uint256 weightRatio = poolState.weights[i] * 1e18 / poolState.weights[minTokenIndex];
            testAmounts[i] = testAmount * weightRatio / 1e18;
        }
        
        console.log("Proportional amounts for test:");
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
            console.log("  ", name, ":", testAmounts[i]);
            console.log("    balance:", balances[i]);
        }
        
        // Check if this would work
        bool allFit = true;
        for (uint i = 0; i < 8; i++) {
            if (testAmounts[i] > balances[i]) {
                allFit = false;
                string memory name;
                if (i == 0) name = "weETH";
                else if (i == 1) name = "WETH";
                else if (i == 2) name = "DAI";
                else if (i == 3) name = "OLAS";
                else if (i == 4) name = "USDC";
                else if (i == 5) name = "DRV";
                else if (i == 6) name = "cbBTC";
                else name = "LBTC";
                console.log("  FAILS: ", name);
                console.log("    amount", testAmounts[i]);
                console.log("    exceeds balance", balances[i]);
            }
        }
        
        if (allFit) {
            console.log("SUCCESS: All amounts fit within balances");
        } else {
            console.log("FAILS: Some amounts exceed balances");
        }
        
        // Calculate total value
        uint256 totalValue = 0;
        for (uint i = 0; i < 8; i++) {
            totalValue += testAmounts[i];
        }
        console.log("Total value for test:", totalValue);
        
        uint256 estimatedBpt = estimateBptOutput(testAmounts, poolState);
        console.log("Estimated BPT for test:", estimatedBpt);
    }
} 