// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./crowdsale/Crowdsale.sol";
import "./crowdsale/emission/AllowanceCrowdsale.sol";
import "./crowdsale/validation/CappedCrowdsale.sol";
import "./crowdsale/validation/TimedCrowdsale.sol";
import "./crowdsale/validation/WhitelistCrowdsale.sol";

contract GYFICrowdsale is Crowdsale, AllowanceCrowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistCrowdsale {
    using SafeMath for uint256;

    uint256 public perBeneficiaryCap;

    mapping(address => uint256) public contribution;

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        address tokenWallet,
        uint256 cap,
        uint256 openingTime,
        uint256 closingTime,
        uint256 _perBeneficiaryCap
    )
        Crowdsale(rate, wallet, token)
        AllowanceCrowdsale(tokenWallet)
        CappedCrowdsale(cap)
        TimedCrowdsale(openingTime, closingTime)
        WhitelistAdminRole()
    {
        perBeneficiaryCap = _perBeneficiaryCap;
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override(Crowdsale, AllowanceCrowdsale) {
        AllowanceCrowdsale._deliverTokens(beneficiary, tokenAmount);
    }
    
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override(Crowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistCrowdsale) view {
        // Per beneficiary cap
        require(contribution[beneficiary].add(weiAmount) <= perBeneficiaryCap, "GYFICrowdsale: Contribution above cap.");

        CappedCrowdsale._preValidatePurchase(beneficiary, weiAmount);
        TimedCrowdsale._preValidatePurchase(beneficiary, weiAmount);
        WhitelistCrowdsale._preValidatePurchase(beneficiary, weiAmount);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal override {
        contribution[beneficiary] = contribution[beneficiary].add(weiAmount);
    }
}