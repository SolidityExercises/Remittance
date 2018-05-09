interface ICurrency {
    function transfer(address to, uint tokens) external returns (bool success);
}
