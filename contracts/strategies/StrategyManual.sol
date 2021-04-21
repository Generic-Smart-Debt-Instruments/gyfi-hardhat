// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StrategyBase.sol";
import "./IGAUC.sol";
import "./IGSDIWallet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StrategyManual is StrategyBase, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");

    uint256 public constant feeBasisPoints = 2500;

    address public feeRecipient;

    IGAUC gauc;

    modifier onlyHarvester {
        require(
            hasRole(HARVESTER_ROLE, msg.sender),
            "Strategy: Sender does not have HARVESTER_ROLE"
        );
        _;
    }

    constructor(
        address _pool,
        IERC20 _currency,
        IGAUC _gauc,
        address _feeRecipient
    ) StrategyBase(_pool, _currency) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        gauc = _gauc;
        feeRecipient = _feeRecipient;
    }

    function withdraw() external onlyHarvester {
        gauc.withdraw(gauc.balanceAvailable(address(this)));
    }

    function bid(uint256 _auctionId, uint256 _faceValue)
        external
        onlyHarvester
    {
        (, , , uint256 price, , , , , ) = gauc.auctionInfo(_auctionId);
        require(
            _faceValue > price,
            "Strategy: Cannot bid for a face value lower than price"
        );

        uint256 available = gauc.balanceAvailable(address(this));
        if (available < _faceValue) {
            uint256 depositAmount = _faceValue.sub(available);
            currency.approve(address(gauc), depositAmount);
            gauc.deposit(depositAmount, address(this));
        }
        gauc.bid(_auctionId, _faceValue);
    }

    function claim(uint256 _auctionId) external onlyHarvester {
        gauc.claim(_auctionId);
        (
            uint256 auctionEndTimestamp,
            uint256 lowestBid,
            uint256 maturity,
            uint256 price,
            ,
            ,
            ,
            ,

        ) = gauc.auctionInfo(_auctionId);
        outstandingFaceValue = outstandingFaceValue.add(lowestBid);
        _updateOutstandingExpectedInterest();
        uint256 interestPerSecondGSDI =
            _getInterestPerSecond(
                auctionEndTimestamp,
                maturity,
                price,
                lowestBid
            );
        outstandingExpectedInterest = outstandingExpectedInterest.add(
            interestPerSecondGSDI.mul(block.timestamp.sub(auctionEndTimestamp))
        );
        interestPerSecond = interestPerSecond.add(interestPerSecondGSDI);
    }

    function processCover(uint256 _auctionId) external onlyHarvester {
        (
            uint256 auctionEndTimestamp,
            uint256 lowestBid,
            uint256 maturity,
            uint256 price,
            ,
            ,
            ,
            ,

        ) = gauc.auctionInfo(_auctionId);
        _updateOutstandingExpectedInterest();
        uint256 interestPerSecondGSDI =
            _getInterestPerSecond(block.timestamp, maturity, price, lowestBid);
        uint256 totalInterestAdded =
            interestPerSecondGSDI.mul(block.timestamp.sub(auctionEndTimestamp));
        outstandingExpectedInterest = outstandingExpectedInterest.sub(
            totalInterestAdded
        );
        interestPerSecond = interestPerSecond.sub(interestPerSecondGSDI);
        realizedProfit = realizedProfit + int256(lowestBid.sub(price));
    }

    function seize(uint256 _id) external onlyHarvester {
        //TODO: seize the NFT and transfer the wallet to the harvester to process
    }

    function liquidate(uint256 _amount) external onlyHarvester {
        //TODO: harvester, after manually processing the seized wallet, returns the revenue from liquidation.
    }

    function _updateOutstandingExpectedInterest() internal {
        outstandingExpectedInterest = outstandingExpectedInterest.add(
            interestPerSecond.mul(
                block.timestamp.sub(timestampLastInterestUpdate)
            )
        );
        timestampLastInterestUpdate = block.timestamp;
    }

    function _getInterestPerSecond(
        uint256 timestampStart,
        uint256 timestampEnd,
        uint256 valueStart,
        uint256 valueEnd
    ) internal pure returns (uint256) {
        return valueEnd.sub(valueStart).div(timestampEnd.sub(timestampStart));
    }
}
