const Remittance = artifacts.require('../../contracts/Remittance.sol');
const KeccakUtil = artifacts.require('../utils/KeccakUtil.sol');

const assertRevert = require('../utils/assertRevert');
const watchEvent = require('../utils/watchEvent');
const constants = require('../utils/constants');
const increaseTime = require('../utils/increaseTime');

contract('Remittance', ([owner, receiver, sender, exchange, other]) => {
	let sut,
		keccakUtil,
		senderPasswordHash,
		receiverPasswordHash,
<<<<<<< HEAD
		key,
		owner_tax;
=======
		key;
>>>>>>> 2959fb9d63257c86ccad263d4b761db4ba7331e9

	before(async () => {
		web3.eth.defaultAccount = owner;
		keccakUtil = await KeccakUtil.new();
		senderPasswordHash = await keccakUtil.encodePassword.call('exchange-password');
		receiverPasswordHash = await keccakUtil.encodePassword.call('receiver-password');
<<<<<<< HEAD
		key = await keccakUtil.encodeKey.call(senderPasswordHash, receiverPasswordHash, sender, receiver);
		owner_tax = 100;
	});

	beforeEach(async () => {
		sut = await Remittance.new();		
	});

	describe('OWNER_TAX should', async () => {

		it('have exact value', async () => {
			const result = await sut.OWNER_TAX.call();

			assert.equal(result, owner_tax);
		});
	});

	describe('claimFunds should', async () => {

		it('revert when `tx.origin` is not the `_receiverAddress` embedded in the key', async () => {
			await sut.newRemittance(key, { value: 101 });

			const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, receiver, { from: other });

			await assertRevert(result);
		});

		it('subtract passed `_amount` from current remittance value', async () => {
			await sut.newRemittance(key, { value: 101 });

			await sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, receiver, { from: receiver });

			const result = await sut.getFunds(key);

			assert.equal(result.valueOf(), 0);
		});

		it('raise ClaimFundsRequested event when passed valid arguments', async () => {
			await sut.newRemittance(key, { value: 101 });

			const event = sut.ClaimFundsRequested();
			const promiEvent = watchEvent(event);

			await sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, receiver, { from: receiver });

			const result = await promiEvent;
			event.stopWatching();

			assert.equal(result.args.sender, receiver);
			assert.equal(result.args.amount.valueOf(), 101 - owner_tax);
		});

		it('return true marking successful operation when passed valid arguments', async () => {
			await sut.newRemittance(key, { value: 142 });

			const result = await sut.claimFunds.call(senderPasswordHash, receiverPasswordHash, sender, receiver, { from: receiver });

			assert.equal(result, true);
		});
	});

	describe('newRemittance should', async () => {

		it('raise NewRemittanceRequest event when adding new remittance request', async () => {
			const event = sut.NewRemittanceRequest();
			const promiEvent = watchEvent(event);

			const transaction = await sut.newRemittance(key, { value: 101, from: owner });

			const result = await promiEvent;
			event.stopWatching();

			assert.equal(result.args.sender, owner);
			assert.equal(result.args.amount, 101);
		});
	});

	describe('claimFunds should', async () => {

		it('revert when the remittance request is non-existing', async () => {
			const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, receiver, receiver);

			await assertRevert(result);
		});

		it('revert when the remittance request is not expired', async () => {
			await sut.newRemittance(key, { value: 142 });

			const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, receiver);

			await assertRevert(result);
		});

		it('revert when `msg.sender` is not the `_senderAddress` embedded in the key', async () => {
			await sut.newRemittance(key, { value: 101 });

			const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, receiver, { from: other });

			await assertRevert(result);
		});

		it('delete the given remittance request on claim funds back', async () => {
			await sut.newRemittance(key, { value: 101 });
		        const claimBackStartAfter = await sut.getClaimBackStartAfter();
			await increaseTime(claimBackStartAfter.toString(10) * 1);

			await sut.claimBack(key);

			const result = await sut.getFunds(key);

			assert.equal(result.valueOf(), 0);
		});
=======
		key = await keccakUtil.encodeKey.call(senderPasswordHash, receiverPasswordHash, receiver, sender);
	});

	beforeEach(async () => {
		sut = await Remittance.new();
	});

	it('OWNER_TAX constant Should have exact value', async () => {
		// Arrange
		// Act
		const result = await sut.OWNER_TAX.call();
		// Assert
		assert.equal(result, 100);
	});

	it('claimFunds Should revert when `tx.origin` is not the `_receiverAddress` embedded in the key', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });
		// Act
		const result = await sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, { from: other });
		// Assert
		await assertRevert(result);
	});

	it('claimFunds Should subtract passed `_amount` from current remittance value', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });
		// Act
		await sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, { from: receiver });

		const result = await sut.remittances.call(key);
		// Assert
		assert.equal(result[0], 42);
	});

	it('claimFunds Should raise ClaimFundsRequested event when passed valid arguments', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });

		const event = sut.ClaimFundsRequested();
		const promiEvent = watchEvent(event);
		// Act
		await sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, { from: receiver });

		const result = await promiEvent;
		event.stopWatching();
		// Assert
		assert.equal(result.args.sender, sender);
	});

	it('claimFunds Should return true marking successful operation when passed valid arguments', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });
		// Act
		const result = await sut.claimFunds.call(senderPasswordHash, receiverPasswordHash, sender, { from: receiver });

		// Assert
		assert.equal(result, true);
	});

	it('newRemittance Should raise NewRemittanceRequest event when adding new remittance request', async () => {
		const event = sut.NewRemittanceRequest();
		const promiEvent = watchEvent(event);
		// Act
		const transaction = await sut.newRemittance(key, { value: 142 });

		const result = await promiEvent;
		event.stopWatching();

		// Assert
		assert.equal(result.args.sender, sender);
		assert.equal(result.args.amount, 142);
	});

	it('claimFunds Should revert when the remittance request is non-existing', async () => {
		// Arrange
		// Act
		const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, receiver);
		// Assert
		await assertRevert(result);
	});

	it('claimFunds Should revert when the remittance request is not expired', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });
		// Act
		const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender);
		// Assert
		await assertRevert(result);
	});

	it('claimFunds Should revert when `msg.sender` is not the `_senderAddress` embedded in the key', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });
		// Act
		const result = sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, { from: other });
		// Assert
		await assertRevert(result);
	});

	it('claimFunds Should delete the given remittance request when passed valid arguments', async () => {
		// Arrange
		await sut.newRemittance(key, { value: 142 });
                const remittance = await sut.remittances.call(key);
		await increaseTime(remittance.claimBackEndDate + 1);
		// Act
		await sut.claimFunds(senderPasswordHash, receiverPasswordHash, sender, { from: sender });

		const result = await sut.remittances.call(key);
		// Assert
		assert.equal(result.funds, 0);
>>>>>>> 2959fb9d63257c86ccad263d4b761db4ba7331e9
	});
});
