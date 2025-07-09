// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {IService} from "./interfaces/IService.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {IToken, INFToken} from "./interfaces/IToken.sol";

// Multisig interface
interface IMultisig {
    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() external view returns (address[] memory);
}

/// @dev Zero address.
error ZeroAddress();

/// @dev Zero value.
error ZeroValue();

/// @dev Caught reentrancy violation.
error ReentrancyGuard();

/// @dev Service is already created and staked.
/// @param serviceId Service Id.
/// @param multisig Multisig address.
error ServiceAlreadyStaked(uint256 serviceId, address multisig);

/// @dev Wrong staking instance.
/// @param stakingInstance Staking instance address.
error WrongStakingInstance(address stakingInstance);

/// @dev Wrong provided service setup.
/// @param serviceId Service Id.
/// @param multisig Multisig address.
error WrongServiceSetup(uint256 serviceId, address multisig);

/// @dev Service is not defined for the sender.
/// @param sender Sender address.
error ServiceNotDefined(address sender);

/// @dev Wrong value provided.
error WrongValue();

// Struct for service info
struct ServiceInfo {
    // Liquidity traded
    uint256 liquidity;
    // Service Id
    uint256 serviceId;
    // Corresponding service multisig
    address multisig;
    // Staking instance address
    address stakingInstance;
}

/// @title StakingManager - Smart contract for managing minimal effort service staking
abstract contract StakingManager is ERC721TokenReceiver {
    event CreatedAndStaked(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
    event Staked(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
    event Unstaked(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);
    event Claimed(address indexed sender, uint256 serviceId, address indexed multisig, address stakingInstance);

    // Contract version
    string public constant VERSION = "0.1.0";

    // Number of agent instances
    uint256 public constant NUM_AGENT_INSTANCES = 1;
    // Threshold
    uint256 public constant THRESHOLD = 1;
    // Agent Id
    uint256 public immutable agentId;
    // Service config hash
    bytes32 public immutable configHash;
    // Service manager address
    address public immutable serviceManager;
    // OLAS token address
    address public immutable olas;
    // Service registry address
    address public immutable serviceRegistry;
    // Service registry token utility address
    address public immutable serviceRegistryTokenUtility;
    // Staking factory address
    address public immutable stakingFactory;
    // Safe multisig processing contract address
    address public immutable safeMultisig;
    // Safe fallback handler
    address public immutable fallbackHandler;

    // Nonce
    uint256 internal _nonce;
    // Reentrancy lock
    uint256 internal _locked = 1;

    // Mapping of account address => service info
    mapping(address => ServiceInfo) public mapAccountServiceInfo;

    /// @dev LiquidityManager constructor.
    /// @param _serviceManager Service manager address.
    /// @param _olas OLAS token address.
    /// @param _stakingFactory Staking factory address.
    /// @param _safeMultisig Safe multisig address.
    /// @param _fallbackHandler Multisig fallback handler address.
    /// @param _agentId Agent Id.
    /// @param _configHash Service config hash.
    constructor(
        address _serviceManager,
        address _olas,
        address _stakingFactory,
        address _safeMultisig,
        address _fallbackHandler,
        uint256 _agentId,
        bytes32 _configHash
    ) {
        // Check for zero addresses
        if (_serviceManager == address(0) || _olas == address(0) || _stakingFactory == address(0) ||
            _safeMultisig == address(0) || _fallbackHandler == address(0)) {
            revert ZeroAddress();
        }

        // Check for zero values
        if (_agentId == 0 || _configHash == 0) {
            revert ZeroValue();
        }

        agentId = _agentId;
        configHash = _configHash;

        serviceManager = _serviceManager;
        olas = _olas;
        stakingFactory = _stakingFactory;
        safeMultisig = _safeMultisig;
        fallbackHandler = _fallbackHandler;
        serviceRegistry = IService(serviceManager).serviceRegistry();
        serviceRegistryTokenUtility = IService(serviceManager).serviceRegistryTokenUtility();
    }

    /// @dev Creates and deploys a service.
    /// @param token Staking token address.
    /// @param minStakingDeposit Min staking deposit value.
    /// @return serviceId Minted service Id.
    /// @return multisig Service multisig.
    function _createAndDeploy(
        address token,
        uint256 minStakingDeposit
    ) internal returns (uint256 serviceId, address multisig) {
        // Set agent params
        IService.AgentParams[] memory agentParams = new IService.AgentParams[](NUM_AGENT_INSTANCES);
        agentParams[0] = IService.AgentParams(uint32(NUM_AGENT_INSTANCES), uint96(minStakingDeposit));

        // Set agent Ids
        uint32[] memory agentIds = new uint32[](NUM_AGENT_INSTANCES);
        agentIds[0] = uint32(agentId);

        // Set agent instances as [msg.sender]
        address[] memory instances = new address[](NUM_AGENT_INSTANCES);
        instances[0] = msg.sender;

        // Create a service owned by this contract
        serviceId = IService(serviceManager).create(address(this), token, configHash, agentIds,
            agentParams, uint32(THRESHOLD));

        // Check msg.value
        if (msg.value != 1 + NUM_AGENT_INSTANCES) {
            revert WrongValue();
        }

        // Activate registration (1 wei as a deposit wrapper)
        IService(serviceManager).activateRegistration{value: 1}(serviceId);

        // Register msg.sender as an agent instance (numAgentInstances wei as a bond wrapper)
        IService(serviceManager).registerAgents{value: NUM_AGENT_INSTANCES}(serviceId, instances, agentIds);

        // Prepare Safe multisig data
        uint256 localNonce = _nonce;
        uint256 randomNonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, localNonce)));
        bytes memory data = abi.encodePacked(address(0), fallbackHandler, address(0), address(0), uint256(0),
            randomNonce, "0x");
        // Deploy the service
        multisig = IService(serviceManager).deploy(serviceId, safeMultisig, data);

        // Update the nonce
        _nonce = localNonce + 1;
    }

    /// @dev Stakes the already deployed service.
    /// @param serviceId Service Id.
    /// @param multisig Corresponding service multisig.
    /// @param stakingInstance Staking instance.
    function _stake(uint256 serviceId, address multisig, address stakingInstance) internal {
        // Add the service into its sender corresponding record
        mapAccountServiceInfo[msg.sender] = ServiceInfo(0, serviceId, multisig, stakingInstance);

        // Approve service NFT for the staking instance
        INFToken(serviceRegistry).approve(stakingInstance, serviceId);

        // Stake the service
        IStaking(stakingInstance).stake(serviceId);
    }

    /// @dev Creates and deploys a service, and stakes it with a specified staking contract.
    /// @notice The service cannot be registered again if it is currently staked.
    /// @param stakingInstance Staking instance address.
    function createAndStake(address stakingInstance) external payable {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for existing service corresponding to the msg.sender
        ServiceInfo memory serviceInfo = mapAccountServiceInfo[msg.sender];
        if (serviceInfo.serviceId > 0) {
            revert ServiceAlreadyStaked(serviceInfo.serviceId, serviceInfo.multisig);
        }

        // Check for staking instance validity
        if(!IStaking(stakingFactory).verifyInstance(stakingInstance)) {
            revert WrongStakingInstance(stakingInstance);
        }

        // Get the token info from the staking contract
        // If this call fails, it means the staking contract does not have a token and is not compatible
        address token = IStaking(stakingInstance).stakingToken();
        // Check the token address
        if (token != olas) {
            revert WrongStakingInstance(stakingInstance);
        }

        // Get other service info for staking
        uint256 minStakingDeposit = IStaking(stakingInstance).minStakingDeposit();
        uint256 numAgentInstances = IStaking(stakingInstance).numAgentInstances();
        uint256 threshold = IStaking(stakingInstance).threshold();
        // Check for number of agent instances that must be equal to one,
        // since msg.sender is the only service multisig owner
        if ((numAgentInstances > 0 &&  numAgentInstances != NUM_AGENT_INSTANCES) ||
            (threshold > 0 && threshold != THRESHOLD)) {
            revert WrongStakingInstance(stakingInstance);
        }

        // Calculate the total bond required for the service deployment:
        uint256 totalBond = (1 + NUM_AGENT_INSTANCES) * minStakingDeposit;

        // Transfer total bond amount from sender
        IToken(olas).transferFrom(msg.sender, address(this), totalBond);
        // Approve token for the serviceRegistryTokenUtility contract
        IToken(olas).approve(serviceRegistryTokenUtility, totalBond);

        // Create and deploy service
        (serviceInfo.serviceId, serviceInfo.multisig) = _createAndDeploy(olas, minStakingDeposit);

        // Stake the service
        _stake(serviceInfo.serviceId, serviceInfo.multisig, stakingInstance);

        emit CreatedAndStaked(msg.sender, serviceInfo.serviceId, serviceInfo.multisig, stakingInstance);

        _locked = 1;
    }

    /// @dev Stakes the already deployed service.
    /// @param serviceId Service Id.
    /// @param stakingInstance Staking instance.
    function stake(uint256 serviceId, address stakingInstance) external {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for existing service corresponding to the msg.sender
        ServiceInfo memory serviceInfo = mapAccountServiceInfo[msg.sender];
        if (serviceInfo.serviceId > 0) {
            revert ServiceAlreadyStaked(serviceInfo.serviceId, serviceInfo.multisig);
        }

        // Get the service multisig
        (, serviceInfo.multisig, , , , , ) = IService(serviceRegistry).mapServices(serviceId);

        // Check that the service multisig owner is msg.sender
        uint256 numAgentInstances = IStaking(stakingInstance).numAgentInstances();
        address[] memory multisigOwners = IMultisig(serviceInfo.multisig).getOwners();
        if (multisigOwners.length != numAgentInstances || multisigOwners[0] != msg.sender) {
            revert WrongServiceSetup(serviceId, serviceInfo.multisig);
        }

        // Transfer the service NFT
        INFToken(serviceRegistry).safeTransferFrom(msg.sender, address(this), serviceId);

        // Stake the service
        _stake(serviceId, serviceInfo.multisig, stakingInstance);

        emit Staked(msg.sender, serviceId, serviceInfo.multisig, stakingInstance);

        _locked = 1;
    }

    /// @dev Unstakes service Id corresponding to the msg.sender and clears the record.
    function unstake() external {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for existing service corresponding to the sender
        ServiceInfo memory serviceInfo = mapAccountServiceInfo[msg.sender];
        if (serviceInfo.serviceId == 0) {
            revert ServiceNotDefined(msg.sender);
        }

        // Unstake service
        IStaking(serviceInfo.stakingInstance).unstake(serviceInfo.serviceId);

        // Terminate service
        IService(serviceManager).terminate(serviceInfo.serviceId);

        // Unbond service
        (, uint256 refund) = IService(serviceManager).unbond(serviceInfo.serviceId);

        // Transfer back OLAS tokens
        IToken(olas).transfer(msg.sender, refund * 2);

        // Transfer the service back to the original owner
        INFToken(serviceRegistry).transferFrom(address(this), msg.sender, serviceInfo.serviceId);

        // Zero the service info: the service is out of the sender records
        delete mapAccountServiceInfo[msg.sender];

        emit Unstaked(msg.sender, serviceInfo.serviceId, serviceInfo.multisig, serviceInfo.stakingInstance);

        _locked = 1;
    }

    /// @dev Claims rewards for the service corresponding to msg.sender.
    /// @return reward Staking reward.
    function claim() external returns (uint256 reward) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for existing service corresponding to the sender
        ServiceInfo memory serviceInfo = mapAccountServiceInfo[msg.sender];
        if (serviceInfo.serviceId == 0) {
            revert ServiceNotDefined(msg.sender);
        }

        // Claim staking rewards
        reward = IStaking(serviceInfo.stakingInstance).claim(serviceInfo.serviceId);

        emit Claimed(msg.sender, serviceInfo.serviceId, serviceInfo.multisig, serviceInfo.stakingInstance);

        _locked = 1;
    }

    /// @dev receives back wei-s from service registries
    receive() external payable {}
}