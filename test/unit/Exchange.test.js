const Exchange = artifacts.require('../../contracts/Exchange.sol');
const CurrencyMock = artifacts.require('./fakes/CurrencyMock.sol');
const RemittanceMock = artifacts.require('./fakes/RemittanceMock.sol');

const assertRevert = require('../utils/assertRevert');
const watchEvent = require('../utils/watchEvent');
const assertThrow = require('../utils/assertThrow');

contract('Exchange', ([owner, other]) => {
	let sut,
	owner_tax,
	localCurrency,
	remittance;

	const defaultExchangeRate = '2000000000000000000';
	const zeroAddress = '0x0000000000000000000000000000000000000000';
	const notUsed = '0x00000000000000000000000000000000000000ff';

	before(() => {
		web3.eth.defaultAccount = owner;
	});

	beforeEach(async () => {
		localCurrency = await CurrencyMock.new();
		remittance = await RemittanceMock.new();
		owner_tax = 100;

		sut = await Exchange.new(remittance.address);
		remittance.setExchangeStatus(sut.address, true);
	});

	describe('constructor should', async () => {

		it('revert when passed empty `_remittance` address', async () => {
			const result = Exchange.new(zeroAddress);

			await assertRevert(result);
		});

		it('set proper `remittance` instance when passed valid arguments', async () => {
			const result = await sut.remittance.call();

			assert.equal(result, remittance.address);
		});
	});

	describe('convertFunds should', async () => {

		it('revert when `remittance.claimFunds` returns false', async () => {
			const transferValue = 42;
			await web3.eth.sendTransaction({ to: remittance.address, value: transferValue});

			const result = sut.convertFunds(notUsed, notUsed, notUsed, notUsed, localCurrency.address);

			await assertRevert(result);
		});

		it('add exact currency amount to `msg.sender` balance when the exchange rate is under a unit', async () => {
			const transferValue = web3.toWei(2, 'ether');
			const expectedBalance = web3.toWei(4, 'ether');
			await web3.eth.sendTransaction({ to: remittance.address, value: transferValue });
			
			await sut.setExchangeRate(localCurrency.address, 2);
			await sut.convertFunds(notUsed, notUsed, notUsed, notUsed, localCurrency.address);

			const result = await sut.getCurrencyBalance(localCurrency.address);

			assert.equal(result.valueOf(), expectedBalance - owner_tax);
		});

		it('raise ConversionPerformed event when passed valid arguments', async () => {
			const event = sut.ConversionPerformed();
			const promiEvent = watchEvent(event);

			const transferValue = web3.toWei(1, 'ether');
			await web3.eth.sendTransaction({ to: remittance.address, value: transferValue });

			await sut.setExchangeRate(localCurrency.address, 2);
			await sut.convertFunds(notUsed, notUsed, notUsed, notUsed, localCurrency.address);

			const result = await promiEvent;
			event.stopWatching();
			assert.equal(result.args.sender, notUsed);
			assert.equal(result.args.recipient, owner);
			assert.equal(result.args.currency, localCurrency.address);
			assert.equal(result.args.amount.valueOf(), transferValue);
		});
	});

	describe('withdrawFunds should', async () => {

		it('revert when the `msg.sender` has not got enough balance', async () => {
			const result = sut.withdrawFunds(localCurrency.address);

			await assertRevert(result);
		});

		it('lower the `msg.sender` balance with exact value when passed valid arguments', async () => {
			const transferValue = web3.toWei(1, 'ether');
			await web3.eth.sendTransaction({ to: remittance.address, value: transferValue });
			await sut.setExchangeRate(localCurrency.address, 2);
			await sut.convertFunds(notUsed, notUsed, notUsed, notUsed, localCurrency.address);
			const ownerBalance = await sut.getCurrencyBalance(localCurrency.address);

			await sut.withdrawFunds(localCurrency.address);

			const ownerNewBalance = await sut.getCurrencyBalance(localCurrency.address);

			assert.equal(ownerNewBalance, 0);
		});

		it('raise WithdrawalPerformed event when passed valid arguments', async () => {
			const transferValue = web3.toWei(1, 'ether');
			await web3.eth.sendTransaction({ to: remittance.address, value: transferValue });
			await sut.setExchangeRate(localCurrency.address, 2);
			await sut.convertFunds(notUsed, notUsed, notUsed, notUsed, localCurrency.address);
			const event = sut.WithdrawalPerformed();
			const promiEvent = watchEvent(event);

			const amount = sut.withdrawFunds(localCurrency.address);


			const result = await promiEvent;
			event.stopWatching();

			assert.equal(result.args.requestor, owner);
			assert.equal(result.args.currency, localCurrency.address);
		});
	});

	describe('withdrawFunds should', async () => {

		it('setExchangeRate should revert when invoked not from the contract owner', async () => {
			const newExchangeRate = 3;

			const result = sut.setExchangeRate(localCurrency.address, newExchangeRate, { from: other });

			assertRevert(result);
		});

		it('setExchangeRate should raise ExchangeRateSet event', async () => {
			const newExchangeRate = 3;
			const event = sut.ExchangeRateSet();
			const promiEvent = watchEvent(event);

			await sut.setExchangeRate(localCurrency.address, newExchangeRate);

			const result = await promiEvent;
			event.stopWatching();

			assert.equal(result.args.currency, localCurrency.address);
			assert.equal(result.args.rate.valueOf(), newExchangeRate);
		});
	});
});
