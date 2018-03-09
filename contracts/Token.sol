pragma solidity ^0.4.15;

import './interfaces/ERC20Interface.sol';

/**
 * @title Token
 * @dev Contract that implements ERC20 token standard
 * Is deployed by `Crowdsale.sol`, keeps track of balances, etc.
 */

contract Token is ERC20Interface {
    using SafeMath for uint256;
    
	// The initial supply of tokens 
	uint256 public constant initial_supply = 10;

    // Total num tokens
    uint256 public totalSupply;
    
    // Cap on initial number of tokens 
    uint256 public cap;
    
    // Beneficiary balances
    mapping(address => uint256) balances;
    
	function Token(uint256 _initial_supply, uint256 _cap) public {
		require(_initial_supply > 0);
		require(_cap > 0);
		
		initial_supply = _initial_supply;
		cap = _cap;
		
	}
	
	/// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {
        // Approve first! 
        approve(_from, _value);
        
        // Should never be sending to this special address
        require(_to != 0x0);
        
        // Can't send more than we have -- although this check may be redundant because we all approve() above
        uint256 sender_balance = balances[msg.sender];
        require(_value <= sender_balance);
        
        // Invoke Transfer event first and then update states
        if (Transfer(msg.sender, _to, _value)) {
            balances[msg.sender] = sub(sender_balance, _value);
            balances[_to] = add(balances[_to], _value);
            return True;
        } else {
            return False;
        }
        
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // Approve first! 
        approve(_from, _value);
        
        // Should never be sending to this special address
        require(_to != 0x0);
        require(_from != 0x0);
        
        // Can't send more than we have -- although this check may be redundant because we all approve() above
        uint256 sender_balance = balances[_from];
        require(_value <= sender_balance);
        
        // Invoke Transfer event first and then update states
        if (Transfer(_from, _to, _value)) {
            balances[_from] = sub(sender_balance, _value);
            balances[_to] = add(balances[_to], _value);
            return True;
        } else {
            return False;
        }
    }

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {
        require(balances[_spender] <= _value);
        
        if (Approval(msg.sender, _spender, _value)) {
            return true;
        } else {
            return false;
        }
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        
    }
    
    // Returns true if successfully refunded the msg.sender
    function refundTokens(uint256 _amount) returns (bool) {
        require(msg.sender.send(_amount));
        return true;
    }
    
    
    // Returns true if successfully minted
    // Is this (and burn?) an internal function?
    function mintTokens(uint256 _amount) internal returns (bool) {
        require(_to != 0x0);
        
        newTokenAmt = add(totalSupply, _amount);
        if (add(newTokenAmt, totalSupply) <= cap) {
            totalSupply = add(totalSupply, newTokenAmt);
            return true;
        } else {
            return false;
        }
    }
    
    // Returns true if successfully burned _amount worth of tokens
    function burnTokens(uint256 _amount) internal returns (bool) {
        require(_amount <= totalSupply);
        
        totalSupply = sub(totalSupply, _amount);
    } 
    
    
    //event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
