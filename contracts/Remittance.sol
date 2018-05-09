pragma solidity ^0.4.21;

import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/zeppelin-solidity/contracts/lifecycle/Destructible.sol';

contract Remittance is Destructible {
        using SafeMath for uint256;

        event NewRemittanceRequest(address indexed sender, uint256 amount);
        event ClaimFundsRequested(address indexed sender, uint256 amount);

        uint256 public constant claimBackStartAfter = 1 weeks;
        uint256 public constant claimBackDuration = 2 weeks;

        struct RemittanceData {
                uint256 funds;
                uint256 claimBackStartDate;
                uint256 claimBackEndDate;
                address sentFrom;
        }
    
        //Flat owner tax for every remittance request.
        uint24 public constant OWNER_TAX = 100;

        mapping(bytes32 => RemittanceData) public remittances;

        //keccak256(senderPassHash, recipientPassHash, senderAddress, recipientAddress) => bytes32
        function newRemittance(bytes32 _remittanceHash) public payable {
                require(msg.value > OWNER_TAX);

                remittances[_remittanceHash].funds = remittances[_remittanceHash].funds.add(msg.value - OWNER_TAX);
                remittances[_remittanceHash].sentFrom = msg.sender;

                //if claim back period is over, sender is not allowed to claim his funds even if he sends more funds
                if(remittances[_remittanceHash].claimBackStartDate == 0){
                        remittances[_remittanceHash].claimBackStartDate = now.add(claimBackStartAfter);
                        remittances[_remittanceHash].claimBackEndDate = remittances[_remittanceHash].claimBackStartDate + claimBackDuration;
                }

	        emit NewRemittanceRequest(msg.sender, msg.value);
        }

        function claimFunds (
                bytes32 _senderPassHash,
                bytes32 _recipientPassHash,
                address _senderAddress
        ) public returns(bool success) {
                bytes32 remittanceHash = keccak256(_senderPassHash, _recipientPassHash, _senderAddress, tx.origin);

                RemittanceData memory remmitance = remittances[remittanceHash];

                require(remmitance.funds > 0);

                //claim funds back
	        if(remmitance.sentFrom == msg.sender){
	                require(now <= remmitance.claimBackEndDate && now >= remmitance.claimBackStartDate);
	        }

                uint256 funds = remmitance.funds;

                delete remittances[remittanceHash];

                msg.sender.transfer(funds);

	        emit ClaimFundsRequested(msg.sender, funds);

	        return true;
        }
}
