pragma solidity ^0.4.21;

import '../../../contracts/Remittance.sol';

contract RemittanceMock is Remittance {
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
}
