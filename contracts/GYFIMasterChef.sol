// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IGYFIMasterChef.sol";
import "./GYFIToken.sol";

/// @title Generic Smart Debt Instrument NFTs for lending against generic assets including vaults. Forked from Sushi's MasterChef.
/// @author jkp
contract GYFIMasterChef is Ownable, IGYFIMasterChef {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of GYFIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGyfiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGyfiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. GYFIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that GYFIs distribution occurs.
        uint256 accGyfiPerShare; // Accumulated GYFIs per share, times 1e12. See below.
    }

    // The GYFI TOKEN!
    GYFIToken public gyfi;
    // Gov address.
    address public governance;
    // Dev address.
    address public devaddr;
    // Block number when bonus GYFI period ends.
    uint256 public override bonusEndBlock;
    // GYFI tokens created per block.
    uint256 public override gyfiPerBlock;
    // Bonus muliplier for early gyfi makers.
    uint256 public bonusMultiplier = 10;
    // Info of each pool.
    PoolInfo[] public override poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when GYFI mining starts.
    uint256 public override startBlock;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(governance == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(
        GYFIToken _gyfi,
        address _governance,
        address _devaddr,
        uint256 _gyfiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        gyfi = _gyfi;
        governance = _governance;
        devaddr = _devaddr;
        gyfiPerBlock = _gyfiPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    /// @return poolLength_ Total number of pools.
    function poolLength() public view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Create a new reward pool. Only callable by owner.
    /// @param _allocPoint Allocation points assigned to pool, affects percentage of GYFI to pool.
    /// @param _token Token deposited to the pool.
    /// @param _withUpdate Whether to update all the pools. Usually should be true except when saving gas.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) public override onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGyfiPerShare: 0
            })
        );
    }

    /// @notice Sets the allocation point for the pool. Only callable by owner.
    /// @param _pid Unique ID for the pool.
    /// @param _allocPoint Allocation points assigned to pool, affects percentage of GYFI to pool.
    /// @param _withUpdate Whether to update all the pools. Usually should be true.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public override onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    /// @param _from start block number.
    /// @param _to end block number.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(bonusMultiplier).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    /// @notice The amount of GYFI pending for the farmer in a pool.
    /// @param _pid Unique ID for the pool.
    /// @param _user Address of the farmer.
    /// @return amount_ Amount of GYFI pending for the farmer to claim.
    function pendingGyfi(uint256 _pid, address _user)
        public
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGyfiPerShare = pool.accGyfiPerShare;
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 gyfiReward =
                multiplier.mul(gyfiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accGyfiPerShare = accGyfiPerShare.add(
                gyfiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accGyfiPerShare).div(1e12).sub(user.rewardDebt);
    }

    /// @notice Update the rewards for all pools.
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update the rewards for one pool.
    /// @param _pid Unique ID for the pool.
    function updatePool(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 gyfiReward =
            multiplier.mul(gyfiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        // no mint -> governance has to transfer tokens to masterchef
        gyfi.transfer(devaddr, gyfiReward.div(10));

        pool.accGyfiPerShare = pool.accGyfiPerShare.add(
            gyfiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    /// @notice Deposit tokens to farm GYFI. Contract must be approved to transfer tokens from the user.
    /// @param _pid Unique ID for the pool.
    /// @param _amount Amount of tokens to deposit.
    function deposit(uint256 _pid, uint256 _amount) public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accGyfiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeGyfiTransfer(msg.sender, pending);
        }
        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accGyfiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw tokens from the pool.
    /// @param _pid Unique ID for the pool.
    /// @param _amount Amount of tokens to withdraw.
    function withdraw(uint256 _pid, uint256 _amount) public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accGyfiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeGyfiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGyfiPerShare).div(1e12);
        pool.token.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw deposited tokens without earning any GYFI rewards.
    /// @param _pid Unique ID for the pool.
    function emergencyWithdraw(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe gyfi transfer function, just in case if rounding error causes pool to not have enough GYFIs.
    function safeGyfiTransfer(address _to, uint256 _amount) internal {
        uint256 gyfiBal = gyfi.balanceOf(address(this));
        if (_amount > gyfiBal) {
            gyfi.transfer(_to, gyfiBal);
        } else {
            gyfi.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Additional functions

    /// @notice Set the bonus multiplier. only callable by governance
    /// @param _bonusMultiplier new bonus mulitplier to be set.
    function setMultiplier(uint256 _bonusMultiplier) public onlyGovernance {
        bonusMultiplier = _bonusMultiplier;
    }
}
