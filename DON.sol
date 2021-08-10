pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DON is ERC20 {
    
    address public admin;
    
    constructor(uint256 initialSupply) ERC20('Don', 'DON') {
        _mint(msg.sender, initialSupply * 10 ** 18);
    }
    
    modifier isAdmin {
        require (msg.sender == admin, 
        'Error: Actor must be admin address.');
        _;
    }
    
    function mint(address account, uint256 amount) public isAdmin {
        _mint(account, amount * 10 ** 18);
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** 18);
    }
    
    function getBalanceOfAccount(address account) public view returns(uint256) {
        return balanceOf(account);
    }
}