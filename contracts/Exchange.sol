pragma solidity ^0.4.21;

import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/zeppelin-solidity/contracts/lifecycle/Destructible.sol';
import '../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol';

import './interfaces/ICurrency.sol';
import './interfaces/IRemittance.sol';

contract Exchange is Destructible {
        using SafeMath for uint256;

        event ExchangeRateSet(address currency, uint256 rate);
        event WithdrawalPerformed(address recipient, address  currency);
        event ConversionPerformed(
	        address indexed sender,
		address indexed recipient,
		address currency,
		uint256 amount
	);

	//Flat owner tax for every convert request.
        uint24 public constant OWNER_TAX = 100;

        address public owner;

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
                owner = msg.sender;
                remittance = IRemittance(_remittance);
        }

        function setExchangeRate(address _currency, uint256 _rate) public onlyOwner {
                exchangeRates[_currency] = _rate;

                emit ExchangeRateSet(_currency, _rate);
        }

        function convertFunds(
                bytes32 _recipientPassHash,
                bytes32 _senderPassHash,
                address _senderAddress,
                address _currency
        ) public hasConvertRate(_currency) {
                uint256 oldBalance = address(this).balance;
                remittance.claimFunds(_senderPassHash, _recipientPassHash, _senderAddress);
                uint256 newBalance = address(this).balance;

                require(newBalance - oldBalance > OWNER_TAX);

                uint256 amount = newBalance.sub(oldBalance + OWNER_TAX);
                uint256 convertedAmount = amount.mul(exchangeRates[_currency]);

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
