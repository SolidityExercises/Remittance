interface IRemittance {
        function claimFunds(
                bytes32 _senderPassHash,
                bytes32 _recipientPassHash,
                address _senderAddress,
		address _recipientAddress
        ) external;
}
