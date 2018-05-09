interface IRemittance {
        function claimFunds(
                bytes32 _senderPassHash,
                bytes32 _recipientPassHash,
                address _recipientAddress
        ) external;
}
