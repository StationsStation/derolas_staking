// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title DerolasPool
 * @notice Contract that accepts ETH, performs multiswap, and provides LP tokens
 * @dev Uses Permit2 for token approvals and Balancer Router for swaps
 */
contract DerolasPool is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Base mainnet addresses
    address public constant ROUTER = 0x3f170631ed9821Ca51A59D996aB095162438DC10;
    address public constant DEROLAS_POOL = 0x7b4c560f33A71A9f7a500aF3C4c65b46fBBafdB7;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    
    // Derolas pool tokens (excluding LBTC due to liquidity issues)
    address public constant WEETH = 0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A;
    address public constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address public constant OLAS = 0x54330d28ca3357F294334BDC454a032e7f353416;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant DRV = 0x9d0E8f5b25384C7310CB8C6aE32C8fbeb645d083;
    address public constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    
    // Pool tokens array (excluding LBTC)
    address[] public poolTokens;
    
    // Events
    event ETHDeposited(address indexed user, uint256 amount);
    event TokensSwapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed user, uint256 lpTokensReceived);
    event LPTransferred(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, address token, uint256 amount);

    // Errors
    error InsufficientETH();
    error SwapFailed();
    error LiquidityAddFailed();
    error InvalidPermit2Signature();
    error InvalidToken();

    constructor() Ownable(msg.sender) {
        // Initialize pool tokens array (excluding LBTC)
        poolTokens = [WEETH, DAI, OLAS, USDC, DRV, CBBTC];
        
        // Approve Permit2 to spend WETH on behalf of this contract
        IERC20(WETH).approve(PERMIT2, type(uint256).max);
    }

    /**
     * @notice Deposit ETH and receive LP tokens
     * @param permit2Signature Permit2 signature for Balancer Router
     * @param permit2Batch Permit2 batch data
     * @param minLpTokens Minimum LP tokens to receive
     * @return lpTokensReceived Amount of LP tokens received
     */
    function depositETHWithPermit2(
        bytes calldata permit2Signature,
        PermitBatch calldata permit2Batch,
        uint256 minLpTokens
    ) external payable nonReentrant whenNotPaused returns (uint256 lpTokensReceived) {
        if (msg.value == 0) revert InsufficientETH();
        
        emit ETHDeposited(msg.sender, msg.value);
        
        // Step 1: Wrap ETH to WETH
        IWETH(WETH).deposit{value: msg.value}();
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        
        // Step 2: Use Permit2 to allow Router to spend WETH
        _usePermit2(permit2Signature, permit2Batch);
        
        // Step 3: Perform multiswap to get all pool tokens
        uint256[] memory tokenAmounts = _performMultiswap(wethBalance);
        
        // Step 4: Add liquidity to Derolas pool
        lpTokensReceived = _addLiquidity(tokenAmounts, minLpTokens);
        
        // Step 5: Transfer LP tokens to user
        IERC20(DEROLAS_POOL).safeTransfer(msg.sender, lpTokensReceived);
        
        emit LPTransferred(msg.sender, lpTokensReceived);
        
        return lpTokensReceived;
    }

    /**
     * @notice Use Permit2 to allow Router to spend tokens
     * @param permit2Signature Permit2 signature
     * @param permit2Batch Permit2 batch data
     */
    function _usePermit2(bytes calldata permit2Signature, PermitBatch calldata permit2Batch) internal {
        try IPermit2(PERMIT2).permit(
            address(this),
            permit2Batch,
            permit2Signature
        ) {
            // Permit2 successful
        } catch {
            revert InvalidPermit2Signature();
        }
    }

    /**
     * @notice Perform multiswap to get all pool tokens
     * @param wethAmount Amount of WETH to swap
     * @return tokenAmounts Array of token amounts received
     */
    function _performMultiswap(uint256 wethAmount) internal returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint256[](poolTokens.length);
        uint256 swapAmount = wethAmount / poolTokens.length;
        uint256 deadline = block.timestamp + 3600;
        
        for (uint256 i = 0; i < poolTokens.length; i++) {
            address tokenOut = poolTokens[i];
            
            // Prepare multicallData for swap
            bytes[] memory multicallData = new bytes[](1);
            multicallData[0] = abi.encodeWithSelector(
                IRouter.swapSingleTokenExactIn.selector,
                DEROLAS_POOL,
                IERC20(WETH),
                IERC20(tokenOut),
                swapAmount,
                0, // minAmountOut (set to 0 for testing)
                deadline,
                false, // wethIsEth (false since we're using WETH)
                "" // userData
            );
            
            // Execute swap using Permit2
            try IRouter(ROUTER).permitBatchAndCall(
                new PermitApproval[](0), // empty permitBatch
                new bytes[](0), // empty permitSignatures
                PermitBatch({
                    permit: new PermitApproval[](0),
                    spender: ROUTER,
                    sigDeadline: deadline
                }),
                "", // empty permit2Signature (we already used it)
                multicallData
            ) returns (bytes[] memory results) {
                // Check if swap was successful
                if (results.length > 0) {
                    uint256 tokenBalance = IERC20(tokenOut).balanceOf(address(this));
                    tokenAmounts[i] = tokenBalance;
                    
                    emit TokensSwapped(msg.sender, WETH, tokenOut, swapAmount, tokenBalance);
                }
            } catch {
                emit TokensSwapped(msg.sender, WETH, tokenOut, swapAmount, 0);
            }
        }
        
        return tokenAmounts;
    }

    /**
     * @notice Add liquidity to Derolas pool
     * @param tokenAmounts Amounts of tokens to add
     * @param minLpTokens Minimum LP tokens to receive
     * @return lpTokensReceived Amount of LP tokens received
     */
    function _addLiquidity(uint256[] memory tokenAmounts, uint256 minLpTokens) internal returns (uint256 lpTokensReceived) {
        uint256 deadline = block.timestamp + 3600;
        
        // Prepare multicallData for liquidity addition
        bytes[] memory multicallData = new bytes[](1);
        multicallData[0] = abi.encodeWithSelector(
            IRouter.addLiquidityProportional.selector,
            DEROLAS_POOL,
            tokenAmounts,
            minLpTokens,
            false, // wethIsEth
            "" // userData
        );
        
        // Execute liquidity addition
        try IRouter(ROUTER).permitBatchAndCall(
            new PermitApproval[](0),
            new bytes[](0),
            PermitBatch({
                permit: new PermitApproval[](0),
                spender: ROUTER,
                sigDeadline: deadline
            }),
            "",
            multicallData
        ) returns (bytes[] memory results) {
            lpTokensReceived = IERC20(DEROLAS_POOL).balanceOf(address(this));
            
            if (lpTokensReceived < minLpTokens) {
                revert LiquidityAddFailed();
            }
            
            emit LiquidityAdded(msg.sender, lpTokensReceived);
        } catch {
            revert LiquidityAddFailed();
        }
        
        return lpTokensReceived;
    }

    /**
     * @notice Emergency withdraw function for owner
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // Withdraw ERC20 token
            IERC20(token).safeTransfer(owner(), amount);
        }
        
        emit EmergencyWithdraw(owner(), token, amount);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Get pool tokens array
     * @return Array of pool token addresses
     */
    function getPoolTokens() external view returns (address[] memory) {
        return poolTokens;
    }

    /**
     * @notice Get contract balance of a token
     * @param token Token address
     * @return Balance of the token
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Get contract ETH balance
     * @return ETH balance
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Receive function to accept ETH
    receive() external payable {
        // Allow receiving ETH
    }
}

// Interfaces
interface IRouter {
    function permitBatchAndCall(
        PermitApproval[] calldata permitBatch,
        bytes[] calldata permitSignatures,
        PermitBatch calldata permit2Batch,
        bytes calldata permit2Signature,
        bytes[] calldata multicallData
    ) external returns (bytes[] memory results);
    
    function swapSingleTokenExactIn(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
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
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IPermit2 {
    function permit(
        address owner,
        PermitBatch calldata permitBatch,
        bytes calldata signature
    ) external;
    
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;
}

// Structs for Permit2
struct PermitApproval {
    address token;
    address spender;
    uint256 amount;
    uint256 expiration;
}

struct PermitBatch {
    PermitApproval[] permit;
    address spender;
    uint256 sigDeadline;
} 