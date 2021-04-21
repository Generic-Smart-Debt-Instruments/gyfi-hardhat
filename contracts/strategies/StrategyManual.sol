// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StrategyBase.sol";
import "./IGAUC.sol";
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
        (, uint256 lowestBid, uint256 maturity, uint256 price, , , , , ) =
            gauc.auctionInfo(_auctionId);
        outstandingFaceValue = outstandingFaceValue.add(lowestBid);
        _updateOutstandingExpectedInterest();
        interestPerSecond = interestPerSecond.add(
            _getInterestPerSecond(block.timestamp, maturity, price, lowestBid)
        );
    }

    function processCover(uint256 _auctionId) external onlyHarvester {
        (
            ,
            uint256 lowestBid,
            uint256 maturity,
            uint256 price,
            ,
            address IGSDIWallet_,
            ,
            ,

        ) = gauc.auctionInfo(_auctionId);
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
