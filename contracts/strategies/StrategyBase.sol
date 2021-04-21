// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IGYFIStrategy.sol";

/// @title Strategy interface for implementing custom strategies to purchase GSDI.
/// @author Crypto Shipwright
contract StrategyBase is IGYFIStrategy {
    using SafeMath for uint256;

    struct  Checkpoint {
        uint64 fromBlock;
        uint64 timestamp;
        uint128 value;
    }

    struct GSDIInfo {
        uint256 purchaseTimestamp;
        uint256 purchasePrice;
        uint256 endTimestamp;
        uint256 interestPerSecondWad;
        int256 profit;
        GSDIStatus status;
    }

    IERC20 public override currency;
    address public override pool;
    uint256 public override totalDeposits;
    int256 public override realizedProfit;
    uint256 public override outstandingFaceValue;
    uint256 public override totalWithdraws;
    uint256 public override totalFees;

    Checkpoint[] interestPerSecondHistory;
    Checkpoint[] outstandingExpectedInterestHistory;

    mapping(uint256 => GSDIInfo) public override gsdiInfo;

    modifier onlyPool() {
        require(msg.sender == pool, "GSDI StrategyBase: Only callable by pool.");
        _;
    }

    function totalValue() public view override returns (uint256 totalValue_)
    {
        if(realizedProfit > 0) {
            return outstandingExpectedInterest().add(totalDeposits).sub(totalWithdraws).sub(totalFees).add(uint256(realizedProfit));
        } else {
            return outstandingExpectedInterest().add(totalDeposits).sub(totalWithdraws).sub(totalFees).sub(uint256(realizedProfit));
        }        
    }
    
    function outstandingExpectedInterest()
        public
        view
        override
        returns (uint256 outstandingExpectedInterest_) 
    {
        (uint256 interest, uint256 timestamp) = outstandingExpectedInterestAt(block.number);
        outstandingExpectedInterest_ = interest.add(
            interestPerSecond().mul(block.timestamp.sub(timestamp))
        );
    }

    function interestPerSecond()
        public
        view
        override
        returns (uint256 interestPerSecond_)
    {
        (interestPerSecond_,) = interestPerSecondAt(block.number);
    }

    function sharePriceWad() external view override returns (uint256 sharePriceWad_) {
        return totalValue().mul(10**18).div(IERC20(pool).totalSupply());
    }

    function withdraw(uint256 _amount, address receiver) override external onlyPool {
        currency.transferFrom(receiver, address(this), _amount);
    }

    function deposit(uint256 _amount, address sender) override external onlyPool {
        currency.transfer(sender, _amount);
    }   

    function interestPerSecondAt(uint256 blockNumber)
        public
        view
        override
        returns (uint256 amount_, uint256 timestamp_)
    {
        return getValueAt(interestPerSecondHistory, blockNumber);
    }

    function outstandingExpectedInterestAt(uint256 blockNumber)
        public
        view
        override
        returns (uint256 amount_, uint256 timestamp_)
    {
        return getValueAt(outstandingExpectedInterestHistory, blockNumber);
    }

    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint value_, uint timestamp_) {
        if (checkpoints.length == 0) return (0,0);

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return (checkpoints[checkpoints.length-1].value, checkpoints[checkpoints.length-1].timestamp);
        if (_block < checkpoints[0].fromBlock) return (0,0);

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return (checkpoints[min].value, checkpoints[min].timestamp);
    }

    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length+1 ];
               newCheckPoint.fromBlock =  uint64(block.number);
               newCheckPoint.timestamp =  uint64(block.timestamp);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }
}
