pragma solidity ^0.4.21;

import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/zeppelin-solidity/contracts/lifecycle/Destructible.sol';

contract Remittance is Destructible {
        using SafeMath for uint256;

        event NewRemittanceRequest(address indexed sender, uint256 amount);
        event ClaimFundsRequested(address indexed sender, uint256 amount);

	//Flat owner tax for every remittance request.
        uint24 public constant OWNER_TAX = 100;

        uint256 public constant claimBackStartAfter = 1 weeks;
        uint256 public constant claimBackDuration = 2 weeks;

        struct RemittanceData {
                uint256 funds;
                uint256 claimBackStartDate;
                uint256 claimBackEndDate;
                address sentFrom;
        }

        mapping(bytes32 => RemittanceData) public remittances;

	mapping(address => bool) public trustedExchanges;

	function () public payable {}

        //keccak256(senderPassHash, recipientPassHash, senderAddress, recipientAddress) => bytes32
        function newRemittance(bytes32 _remittanceHash) public payable {
                require(msg.value > OWNER_TAX);

                remittances[_remittanceHash].funds = remittances[_remittanceHash].funds.add(msg.value - OWNER_TAX);
                remittances[_remittanceHash].sentFrom = msg.sender;

                //if there is another remittane request for the same hash, claim back periods will remain the same
                if(remittances[_remittanceHash].claimBackStartDate == 0){
                        remittances[_remittanceHash].claimBackStartDate = now.add(claimBackStartAfter);
                        remittances[_remittanceHash].claimBackEndDate = remittances[_remittanceHash].claimBackStartDate + claimBackDuration;
                }

	        emit NewRemittanceRequest(msg.sender, msg.value);
        }

        function claimFunds (
                bytes32 _senderPassHash,
                bytes32 _recipientPassHash,
                address _senderAddress,
		address _recipientAddress
        ) public returns(bool success) {
		require(_recipientAddress == msg.sender || trustedExchanges[msg.sender] == true);

                bytes32 remittanceHash = keccak256(_senderPassHash, _recipientPassHash, _senderAddress, tx.origin);

                _transferFunds(remittanceHash, msg.sender);

	        return true;
        }

	function claimBack (bytes32 _remittanceHash) external {
		uint256 claimBackStartDate = getClaimBackStartDate(_remittanceHash);
		uint256 claimBackEndDate = getClaimBackEndDate(_remittanceHash);

		require(now <= claimBackEndDate && now >= claimBackStartDate);

		_transferFunds(_remittanceHash, msg.sender);
	}

	function _transferFunds(bytes32 _remittanceHash, address _recipient) internal {
		require(remittances[_remittanceHash].funds > 0);

		uint256 funds = remittances[_remittanceHash].funds;

		delete remittances[_remittanceHash];
		
		_recipient.transfer(funds);

		emit ClaimFundsRequested(msg.sender, funds);
	}

	function setExchangeStatus(address _exchange, bool _status) external onlyOwner {
		trustedExchanges[_exchange] = _status;
	}

	function getFunds(bytes32 _remittanceHash) external view returns(uint256) {
		return remittances[_remittanceHash].funds;
	}

	function getClaimBackStartAfter() public view returns(uint256) {
		return claimBackStartAfter;
	}

	function getClaimBackStartDate(bytes32 _remittanceHash) public view returns(uint256) {
		return remittances[_remittanceHash].claimBackStartDate;
	}

	function getClaimBackEndDate(bytes32 _remittanceHash) public view returns(uint256) {
		return remittances[_remittanceHash].claimBackEndDate;
	}
}
