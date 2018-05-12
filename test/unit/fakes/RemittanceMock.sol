pragma solidity ^0.4.21;

import '../../../contracts/Remittance.sol';

contract RemittanceMock is Remittance {
<<<<<<< HEAD
	mapping(address => bool) public trustedExchanges;

	modifier onlyOwner() {
		_;
        }

	function () public payable {}

	function claimFunds (
                bytes32 _senderPassHash,
                bytes32 _recipientPassHash,
                address _senderAddress,
		address _recipientAddress
        ) public returns(bool success) {

		msg.sender.transfer(address(this).balance);

		return true;
	}

	function setExchangeStatus(address _exchange) external onlyOwner {
		trustedExchanges[_exchange] = true;
	}
=======
>>>>>>> 2959fb9d63257c86ccad263d4b761db4ba7331e9
}
