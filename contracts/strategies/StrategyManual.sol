// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StrategyBase.sol";
import "gauc/contracts/interfaces/IGAUC.sol";
import "gsdi/contracts/interfaces/IGSDINFT.sol";
import "gsdi/contracts/interfaces/IGSDIWallet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StrategyManual is StrategyBase, AccessControl {
    //TODO: add management fees
    using SafeMath for uint256;

    bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");

    uint256 public constant feeBasisPoints = 2500;

    address public feeRecipient;

    IGAUC gauc;
    IGSDINFT gsdi;

    modifier onlyHarvester {
        require(
            hasRole(HARVESTER_ROLE, msg.sender),
            "StrategyManual: Sender does not have HARVESTER_ROLE"
        );
        _;
    }

    constructor(
        address _pool,
        IERC20 _currency,
        IGAUC _gauc,
        IGSDINFT _gsdi,
        address _feeRecipient
    ) StrategyBase(_pool, _currency) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        gauc = _gauc;
        gsdi = _gsdi;
        feeRecipient = _feeRecipient;
    }

    function withdraw() external onlyHarvester {
        gauc.withdraw(gauc.balanceAvailable(address(this)));
    }

    function bid(uint256 _auctionId, uint256 _faceValue)
        external
        onlyHarvester
    {
        (, , , uint256 price, , , address lowestBidder, , ) =
            gauc.auctionInfo(_auctionId);
        require(
            _faceValue > price,
            "StrategyManual: Cannot bid for a face value lower than price"
        );
        require(
            lowestBidder != address(this),
            "StrategyManual: Strategy must not be lowest bidder"
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
        uint256 tokenId = gauc.claim(_auctionId);
        (
            uint256 maturity,
            uint256 faceValue,
            uint256 price,
            IGSDIWallet wallet,
            ,
            ,

        ) = gsdi.metadata(_auctionId);
        gsdiInfo[tokenId] = GSDIInfo(
            block.timestamp,
            price,
            maturity,
            faceValue,
            address(wallet),
            GSDIStatus.OPEN
        );

        outstandingFaceValue = outstandingFaceValue.add(faceValue);
        _updateOutstandingExpectedInterest();
        interestPerSecond = interestPerSecond.add(
            _getInterestPerSecond(block.timestamp, maturity, price, faceValue)
        );
    }

    function processCover(uint256 _tokenId) external onlyHarvester {
        GSDIInfo memory info = gsdiInfo[_tokenId];
        require(
            info.status == GSDIStatus.OPEN,
            "StrategyManual: gsdiInfo.status is not open"
        );
        gsdiInfo[_tokenId].status = GSDIStatus.COVER;
        _updateInterestOnRemovingGSDI(info);
        realizedProfit =
            realizedProfit +
            int256(info.faceValue.sub(info.purchasePrice));
    }

    function seize(uint256 _id) external onlyHarvester {
        //Transfer the wallet to harvester for manual proccessing.
        gsdi.seize(_id);
        IGSDIWallet wallet = IGSDIWallet(gsdiInfo[_id].wallet);
        wallet.setExecutor(msg.sender);
    }

    function liquidate(uint256 _id, uint256 _amount) external onlyHarvester {
        //harvester, after manually processing the seized wallet, returns the revenue from liquidation.
        GSDIInfo memory info = gsdiInfo[_id];
        require(
            currency.transferFrom(msg.sender, address(this), _amount),
            "StrategyManual: Transfer failed"
        );
        require(
            info.status == GSDIStatus.OPEN,
            "StrategyManual: gsdiInfo.status is not open"
        );
        gsdiInfo[_id].status = GSDIStatus.SEIZE;
        _updateInterestOnRemovingGSDI(info);
        realizedProfit =
            realizedProfit +
            int256(_amount.sub(info.purchasePrice));
    }

    function _updateInterestOnRemovingGSDI(GSDIInfo memory info) internal {
        _updateOutstandingExpectedInterest();
        uint256 interestPerSecondGSDI =
            _getInterestPerSecond(
                info.purchaseTimestamp,
                info.maturity,
                info.purchasePrice,
                info.faceValue
            );
        outstandingExpectedInterest = outstandingExpectedInterest.sub(
            interestPerSecondGSDI.mul(
                block.timestamp.sub(info.purchaseTimestamp)
            )
        );
        interestPerSecond = interestPerSecond.sub(interestPerSecondGSDI);
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
