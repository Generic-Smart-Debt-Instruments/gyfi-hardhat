// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IGYFIStrategy.sol";

/// @title Strategy interface for implementing custom strategies to purchase GSDI.
/// @author Crypto Shipwright
abstract contract StrategyBase is IGYFIStrategy {
    using SafeMath for uint256;

    struct GSDIInfo {
        uint256 purchaseTimestamp;
        uint256 purchasePrice;
        uint256 maturity;
        uint256 faceValue;
        address wallet;
        GSDIStatus status;
    }

    IERC20 public override currency;
    address public override pool;
    uint256 public override totalDeposits;
    int256 public override realizedProfit;
    uint256 public override outstandingFaceValue;
    uint256 public override totalWithdraws;
    uint256 public override totalFees;
    uint256 public override interestPerSecond;
    uint256 public override outstandingExpectedInterest;
    uint256 public override timestampLastInterestUpdate;

    mapping(uint256 => GSDIInfo) public override gsdiInfo;

    modifier onlyPool() {
        require(msg.sender == pool, "StrategyBase: Only callable by pool.");
        _;
    }

    constructor(address _pool, IERC20 _currency) {
        pool = _pool;
        currency = _currency;
    }

    function totalValue() public view override returns (uint256 totalValue_) {
        if (realizedProfit > 0) {
            return
                outstandingExpectedInterest
                    .add(totalDeposits)
                    .sub(totalWithdraws)
                    .sub(totalFees)
                    .add(uint256(realizedProfit));
        } else {
            return
                outstandingExpectedInterest
                    .add(totalDeposits)
                    .sub(totalWithdraws)
                    .sub(totalFees)
                    .sub(uint256(realizedProfit));
        }
    }

    function sharePriceWad()
        external
        view
        override
        returns (uint256 sharePriceWad_)
    {
        return totalValue().mul(10**18).div(IERC20(pool).totalSupply());
    }

    function withdraw(uint256 _amount, address _receiver)
        external
        override
        onlyPool
    {
        _preWithdraw(_amount, _receiver);
        totalWithdraws = totalWithdraws.add(_amount);
        require(
            currency.transferFrom(_receiver, address(this), _amount),
            "StrategyBase: transfer failed"
        );
        _postWithdraw(_amount, _receiver);
    }

    function deposit(uint256 _amount, address _sender)
        external
        override
        onlyPool
    {
        _preDeposit(_amount, _sender);
        totalDeposits = totalDeposits.add(_amount);
        currency.transfer(_sender, _amount);
        _postDeposit(_amount, _sender);
    }

    function _preWithdraw(uint256 _amount, address _receiver)
        internal
        virtual
    {}

    function _postWithdraw(uint256 _amount, address _receiver)
        internal
        virtual
    {}

    function _preDeposit(uint256 _amount, address _sender) internal virtual {}

    function _postDeposit(uint256 _amount, address _sender) internal virtual {}
}
