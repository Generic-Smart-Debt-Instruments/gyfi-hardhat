// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Strategy interface for implementing custom strategies to purchase GSDI.
/// @author Crypto Shipwright
interface IGYFIStrategy {
    enum GSDIStatus {OPEN, COVER, SEIZE, SOLD}

    event GSDIPurchased(uint256 _id);
    event GSDICovered(uint256 _id);
    event GSDISeized(uint256 _id);
    event GSDISold(uint256 _id);

    /// @dev The pool_ must be approved to transfer the currency.
    /// @return pool_ Pool registered with the strategy.
    function pool() external view returns (address pool_);

    /// @return token_ Currenty token that the pool is valued in (such as Dai)
    function currency() external view returns (IERC20 token_);

    /// @dev totalValue should be the sum of expected interest, and total deposits
    /// @dev minus total fees and withdraws. Realized Profits should be added but may be negative.
    /// @return totalValue_ Total value controlled by the pool.
    function totalValue() external view returns (uint256 totalValue_);

    /// @dev Does not affect total value of the pool. Updated whenever a GSDI is added or removed.
    /// @return outstandingFaceValue_ Outstanding face value of all GSDI in the pool.
    function outstandingFaceValue()
        external
        view
        returns (uint256 outstandingFaceValue_);

    /// @dev Adds the outstandingExpectedInterestAt from the most recent to interestPerSecond divided by the time of that snapshot.
    /// @return outstandingExpectedInterest_ Current expected interest.
    function outstandingExpectedInterest()
        external
        view
        returns (uint256 outstandingExpectedInterest_);

    /// @dev Update realized profit whenever a GSDI is removed. May be negative.
    /// @return realizedProfit_ Current realized profit from covered, seized, and sold GSDIs.
    function realizedProfit() external view returns (int256 realizedProfit_);

    /// @return totalDeposits_ Total deposits into the strategy in currency.
    function totalDeposits() external view returns (uint256 totalDeposits_);

    /// @return totalWithdraws_ Total withdraws into the strategy in currency.
    function totalWithdraws() external view returns (uint256 totalWithdraws_);

    /// @return totalFees_ Total fees from the strategy in currency.
    function totalFees() external view returns (uint256 totalFees_);

    /// @dev Update whenever a GSDI is added or removed.
    /// @return interestPerSecond_ Current interest per second.
    function interestPerSecond()
        external
        view
        returns (uint256 interestPerSecond_);

    /// @dev Total value divided by outstanding shares multiplied by 10**18.
    /// @return sharePriceWad_ Current price per share in currency times 10**18.
    function sharePriceWad() external view returns (uint256 sharePriceWad_);

    /// @notice Get the info for a GSDI currently held or held in the past by the strategy.
    /// @dev Caution must be taken if a GSDI is removed and readded later. Most strategies should revert.
    /// @param _id ID of the GSDI.
    /// @return purchaseTimestamp_ Timestamp when the GSDI was purchased.
    /// @return purchasePrice_ Price in currency that the GSDI was purchased at.
    /// @return endTimestamp_ Timestamp when the GSDI was removed. Note that this is when the GSDI's removal was processed, not when it was covered.
    /// @return interestPerSecondWad_ Interest per second times 10**18.
    /// @return profit_ Profit (or loss) in currency when the GSDI was removed.
    /// @return status_ Current status of the GSDI.
    function gsdiInfo(uint256 _id)
        external
        view
        returns (
            uint256 purchaseTimestamp_,
            uint256 purchasePrice_,
            uint256 endTimestamp_,
            uint256 interestPerSecondWad_,
            int256 profit_,
            GSDIStatus status_
        );

    /// @notice Withdraw currency from the contract. Only callable by pool.
    /// @param _amount Amount of currency to withdraw.
    function withdraw(uint256 _amount) external;

    /// @notice Deposit currency to the contract. Only callable by pool.
    /// @param _amount Amount of currency to deposit.
    function deposit(uint256 _amount) external;

    //////////////////////////////////////////
    // For snapshots, See the MiniMe token. //
    //////////////////////////////////////////

    /**
     * @dev Retrieves the interestperSecond at the block number.
     */
    function interestPerSecondAt(address account, uint256 blockNumber)
        external
        view
        returns (uint256 amount_, uint256 timestamp_);

    /**
     * @dev Retrieves the outstandingExpectedInterest at the timestamp.
     */
    function outstandingExpectedInterestAt(address account, uint256 blockNumber)
        external
        view
        returns (uint256 amount_, uint256 timestamp_);
}
