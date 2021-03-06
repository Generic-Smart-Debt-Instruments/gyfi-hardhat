// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StrategyBase.sol";
import "gauc/contracts/interfaces/IGAUC.sol";
import "gsdi/contracts/interfaces/IGSDINFT.sol";
import "gsdi/contracts/interfaces/IGSDIWallet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ILendingPoolAaveMin.sol";

/// @dev Single collateral strategy. Uses a Chainlink oracle for the ERC20 token. See the chainlink documentation.
/// @dev After implementation, switch methods from virtual and remove abstract modifier.
abstract contract StrategyERC20Chainlink is StrategyBase {
    using SafeMath for uint256;

    /// @dev Address responsible for setting parameters.
    address public governance;

    /// @dev GSDI Auction contract.
    IGAUC public gauc;

    /// @dev GSDI NFT contract.
    IGSDINFT public gsdi;

    /// @dev Aave v2 lending pool for dai, dai is held here.
    ILendingPool daiLendingPool;

    /// @dev Collateral token GSDI must be backed by to be bid on.
    IERC20 public collateralToken;

    /// @dev Percentage of face value to collateral value, in percentage points.
    /// example: if the collateral is valued at $100, and collateralizationPercent is 80, then the face value must be 80 or higher.
    uint32 public collateralizationPercent;

    /// @dev Maximum time to maturity, in seconds.
    uint32 public maxTimeToMaturity;

    /// @dev Maximum time to auction end, in seconds.
    uint32 public maxTimeToAuctionEnd;

    /// @dev Max percentage of portfolio to be locked in GSDIs. Remainder is held in aave lending pool.
    uint32 public maxLockedPercent;

    /// @dev Max fee to be taken by caller when liquidating an asset..
    uint32 public maxLiquidationFee;

    /// @notice Sets the governance variables for the strategy. Only callable by governance.
    function setGovernanceVariables(
        uint32 _collateralizationPercent,
        uint32 _maxTimeToMaturity,
        uint32 _maxTimeToAuctionEnd,
        uint32 _maxLockedPercent,
        uint32 _maxLiquidationFee
    ) external virtual;

    /// @notice Updates the governance address. Only callable by governance.
    function setGovernance(address _governance) external virtual;

    /// @notice Withdraws the current unlocked balance on GAUC and deposits it into aave. No restrictions.
    function withdraw() external virtual;

    /// @notice Places a bid at the collateralization percent.
    /// @dev Must check that bid/collateral keeps the collateralization percentage below the maximum.
    /// @dev Cannot bid if the lowestBidder is the strategy. Auction end and maturity parameters must be within governance parameters.
    /// @dev Withdraws dai from the aave lending pool to deposit into the auction, if required.
    function bid(uint256 _auctionId) external virtual;

    /// @notice Claims a GSDI from a winning auction.
    /// @dev Updates outstandingFaceValue, interestPerSecond, gsdiInfo, outstandingExpectedInterest. See StrategyManual.
    function claim(uint256 _auctionId) external virtual; 

    /// @notice Process a GSDI which has been covered. Transfers earned Dai to Aave.
    /// @dev GSDI is covered if the nft token does not exist() and has a current status of OPEN.
    /// @dev Updates outstandingFaceValue, interestPerSecond, gsdiInfo, outstandingExpectedInterest. See StrategyManual.
    function processCover(uint256 _tokenId) external virtual;

    /// @notice Seizes and transfers a defaulted GSDIs assets to sender in exchange for Dai. Transfers Dai to Aave pool.
    /// @dev The amount of Dai must be at least the value of the collateral minus  the liq fee.
    /// @dev Updates outstandingFaceValue, interestPerSecond, gsdiInfo, outstandingExpectedInterest. See StrategyManual, combination of seize and liquidate.
    function seizeAndLiquidate(uint256 _tokenId, uint256 _amountDai) external virtual;


}