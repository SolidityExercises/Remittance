pragma solidity ^0.4.21;

import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/zeppelin-solidity/contracts/lifecycle/Destructible.sol';
import '../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol';

import './interfaces/ICurrency.sol';
import './interfaces/IRemittance.sol';

contract Exchange is Destructible {
        using SafeMath for uint256;

        event ExchangeRateSet(address currency, uint256 rate);
        event WithdrawalPerformed(address requestor, address  currency);
        event ConversionPerformed(
	        address indexed sender,
		address indexed recipient,
		address currency,
		uint256 amount
	);

	//Flat owner tax for every convert request.
        uint24 public constant OWNER_TAX = 100;

        IRemittance public remittance;
    
        mapping(address => uint256) public exchangeRates;
    
        mapping(address => mapping(address => uint256)) public balances;

        modifier addressValid(address _address) {
	        require(_address != address(0));
	        _;
        }

        modifier hasConvertRate(address _currency) {
	        require(exchangeRates[_currency] != 0);
	        _;
        }

        constructor (address _remittance) public addressValid(_remittance) {
                remittance = IRemittance(_remittance);
        }

	function getCurrencyBalance(address _currency) external view returns (uint256) {
		return balances[msg.sender][_currency];
	}

	/**
	* @dev Designed to use this function as setter for trusted currencies
	* The currency should be ERC20 compliant
	* The currency should have set decimals places in order to set exchange rate accordingly from the owner
	*/
        function setExchangeRate(address _currency, uint256 _rate) public onlyOwner {
                exchangeRates[_currency] = _rate;

                emit ExchangeRateSet(_currency, _rate);
        }

	function () public payable {}

        function convertFunds(
                bytes32 _recipientPassHash,
                bytes32 _senderPassHash,
                address _senderAddress,
		address _recipientAddress,
                address _currency
        ) public hasConvertRate(_currency) {
                uint256 oldBalance = address(this).balance;
                remittance.claimFunds(_senderPassHash, _recipientPassHash, _senderAddress, _recipientAddress);
                uint256 newBalance = address(this).balance;

                require(newBalance - oldBalance > OWNER_TAX);

                uint256 amount = newBalance.sub(oldBalance);
                uint256 convertedAmount = amount.mul(exchangeRates[_currency]);
		convertedAmount.sub(OWNER_TAX);

                balances[msg.sender][_currency] = balances[msg.sender][_currency].add(convertedAmount);
 
                emit ConversionPerformed(_senderAddress, msg.sender, _currency, amount);
        }

        function withdrawFunds(address _currency) public  addressValid(_currency) {
                require(balances[msg.sender][_currency] != 0);

                ICurrency currency = ICurrency(_currency);

	        uint256 withdrawalAmount = balances[msg.sender][_currency];

                delete balances[msg.sender][_currency];

                require(currency.transfer(msg.sender, withdrawalAmount));

                emit WithdrawalPerformed(msg.sender, _currency);
        }
}
