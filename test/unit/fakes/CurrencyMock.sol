pragma solidity ^0.4.21;

contract CurrencyMock {
	function transfer(address _to, uint256 _value) public returns (bool success) {
			if (_value == 42) {
				return false;
			}

			return true;
	}
}
