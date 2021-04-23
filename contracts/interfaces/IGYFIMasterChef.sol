// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Generic Smart Debt Instrument NFTs for lending against generic assets including vaults. Forked from Sushi's MasterChef.
/// @author Crypto Shipwright
interface IGYFIMasterChef {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /// @notice Returns the info for a farmer.
    /// @param _pid Unique ID for the pool.
    /// @param _address Address of the farmer.
    /// @return
    /// amount_ Amount of tokens.
    /// rewardDebt_ Reduces rewards to account for deposits/withdraws. See Sush's masterchef for details.
    function userInfo(uint256 _pid, address _address)
        external
        view
        returns (uint256 amount_, uint256 rewardDebt_);

    /// @notice Returns the info for a pool.
    /// @param _pid Unique ID for the pool.
    /// @return
    /// token_ Token deposited to the pool.
    /// allocPoint_ Allocation points assigned to pool, affects percentage of GYFI to pool.
    /// lastRewardBlock_ Last block number that GYFI distribution occured.
    /// accGyfiPerShare_ Accumulated GYFIs per share times 10**12.
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            IERC20 token_,
            uint256 allocPoint_,
            uint256 lastRewardBlock_,
            uint256 accGyfiPerShare_
        );

    /// @return bonusEndBlock_ Block at which the current rewards end.
    function bonusEndBlock() external view returns (uint256 bonusEndBlock_);

    /// @return gyfiPerBlock_ GYFI rewards distributed each block.
    function gyfiPerBlock() external view returns (uint256 gyfiPerBlock_);

    /// @return startBlock_ Block at which the rewards begin.
    function startBlock() external view returns (uint256 startBlock_);

    /// @return poolLength_ Total number of pools.
    function poolLength() external view returns (uint256 poolLength_);

    /// @notice Create a new reward pool. Only callable by owner.
    /// @param _allocPoint Allocation points assigned to pool, affects percentage of GYFI to pool.
    /// @param _token Token deposited to the pool.
    /// @param _withUpdate Whether to update all the pools. Usually should be true except when saving gas.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) external;

    /// @notice Sets the allocation point for the pool. Only callable by owner.
    /// @param _pid Unique ID for the pool.
    /// @param _allocPoint Allocation points assigned to pool, affects percentage of GYFI to pool.
    /// @param _withUpdate Whether to update all the pools. Usually should be true.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    /// @notice The amount of GYFI pending for the farmer in a pool.
    /// @param _pid Unique ID for the pool.
    /// @param _user Address of the farmer.
    /// @return amount_ Amount of GYFI pending for the farmer to claim.
    function pendingGyfi(uint256 _pid, address _user)
        external
        view
        returns (uint256 amount_);

    /// @notice Update the rewards for all pools.
    function massUpdatePools() external;

    /// @notice Update the rewards for one pool.
    /// @param _pid Unique ID for the pool.
    function updatePool(uint256 _pid) external;

    /// @notice Deposit tokens to farm GYFI. Contract must be approved to transfer tokens from the user.
    /// @param _pid Unique ID for the pool.
    /// @param _amount Amount of tokens to deposit.
    function deposit(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraw tokens from the pool.
    /// @param _pid Unique ID for the pool.
    /// @param _amount Amount of tokens to withdraw.
    function withdraw(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraw deposited tokens without earning any GYFI rewards.
    /// @param _pid Unique ID for the pool.
    function emergencyWithdraw(uint256 _pid) external;
}
