pragma solidity ^0.4.15;

import './Queue.sol';
import './Token.sol';

/**
 * @title Crowdsale
 * @dev Contract that deploys `Token.sol`
 * Is timelocked, manages buyer queue, updates balances on `Token.sol`
 */

// [[pls ignore all the stackoverflow comments]]

// Additional functionality beyond spec: Having a cap on the total # of tokens available to be made
// (This makes sense as we probs don't want to generate tokens ad infintinum...)
// Also there is a "goal wei amount", like a goal fundraising amount. Honestly I saw a lot on 
// stackoverflow posts relating to crowdsales, which is why it's here, and without these two 
// features, the contracts aren't really as meaty. 

contract Crowdsale {
    // https://ethereum.stackexchange.com/questions/25829/meaning-of-using-safemath-for-uint256/25831
	using SafeMath for uint256;
	
	// The token being sold
	Token public token; 
	
	// Initial amount of tokens created 
	uint256 public initialNumTokens;
	
	// Num tokens sold so far
	uint256 public numTokensSold;
	
	// Address where funds (invested in token) are collected
	// This is the OWNER's wallet address
	address public wallet;
	
	// How many token units a buyer gets per wei
	uint public rate;
	
	// Goal fundraising amount in wei
	uint256 public goal;
	
	// Total wei raised so far 
	uint256 public weiRaised;
	
	// Whether we can end crowdsale or not. True when weiRaised = goal.
	bool public goalReached;
	
	// Start time of crowdsale (the UNIX time)
	uint256 public startTime;
	
	// End time of crowdsale (the UNIX time)
	uint256 public endTime;
	
	// Queue of buyers
	Queue public buyerQueue;
	
	// So many variables o_o
	
   /**
   * Token purchase event
   * @param indexed_investor person who paid for the tokens
   * @param indexed_beneficiary person who got the tokens
   * @param weiAmount value weis paid for purchase
   * @param tokenAmt amount amount of tokens purchased
   */
   // source: https://ethereum.stackexchange.com/questions/24838/how-to-find-out-how-events-are-implemented-in-solidity-event-tokenpurchase
  event TokenPurchase(address indexed investor, address indexed beneficiary, uint256 weiAmount, uint256 tokenAmt);


    /**
   * Initiates the crowdsale 
   * @param _startTime UNIX start time of crowdsale
   * @param _endTime UNIX end time of crowdsale
   * @param _rate exchange rate to convert from wei invested -> tokens. (i.e. The amount of tokens 1 wei is worth)
   * @param _wallet owner's wallet (an address)
   * @param _token the token being sold in this crowdsale
   * @param _goal goal fundraising amount 
   */
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, Token _token, uint256 _goal, uint256 _initialNumTokens) public {
      // _wallet = address where funds will be sent
      // _token = address of the token being sold
      // _rate = num token units a buyer gets per wei
      require(_rate > 0);
      
      // QUESTION: Do these two actually just mean the same thing? To my understanding they don't, but...
      require(_wallet != 0x0);
      require(_wallet != 0);
      
      require(_token != 0x0);
      require(_endTime > _startTime);
      require(_startTime > 0);
      require(_endTime > 0);
      require(_initialNumTokens > 0);
      
      rate = _rate;
      wallet = _wallet;
      tok = _token;
      goal = _goal;
      goalReached = false;
      initialNumTokens = _initialNumTokens;
      startTime = _startTime;
      endTime = _endTime;
      
      // Initialize queue of buyers
      buyerQueue = Queue();
      
      //IGNORE
      // No date/time object in Solidity which gives you the actual current time?
      // Can only get the timestamp of the block in which the contract is invoked, which is deterministic
      // SOURCE: https://ethereum.stackexchange.com/questions/18192/how-do-you-work-with-date-and-time-on-ethereum-platform
    //   startTime = block.timestamp; 
      
      // Creates token with initial supply, and in the 'cap' argument we pass in (cont.) 
      // the total # tokens we'd need to reach the goal Wei amount
      token = createTokenContract(initialNumTokens, getTokenAmount(goal));
      
  }
  
  // Creates our token, called Token 
  // source: https://ethereum.stackexchange.com/questions/34902/ending-a-crowdsale-contract-before-end-time
  function createTokenContract(uint256 _initialSupply, uint256 _tokenCap) internal returns (Token) {
      return new Token(_initialSupply, _tokenCap);
  }
  
  function buyTokens(address beneficiary) public payable {
      // Referenced: https://github.com/decentraland/mana/blob/master/contracts/ContinuousSale.sol#L83
      
      // Within an Ethereum transaction, the zero-account is just a special case used 
      // to indicate that a new contract is being deployed. 
      // It is literally '0x0' set to the 'to' field in the raw transaction.
      require(beneficiary != 0x0);
      
      // Cannot buy tokens if sale is over
      require(!isGoalReached());
      
      // Cannot buy tokens with zero money
      require(msg.value != 0);
      
      // Beneficiary needs to be in certain position in queue
      require(addressCanPurchase()); // isFirstInQueue() && someoneBehind();
      
      uint256 weiAmount = msg.value;
      // Can't get tokens with zero money
      require(_weiAmount != 0);
  
      // Calculate token amount based on purchase
      uint256 numTokens = getTokenAmount(weiAmount);
      // Make sure not getting more tokens than we have to give (a require, perhaps?)
      // Wait actually no we don't need to check that here, because that check happens in Token.sol
      
      // Or maybe we could mint more?? WHERE DOES THE MINTING HAPPEN 
     
      // Purchase first and then update states 
      // Purchase will fail if numTokens is too large or weiAmount too small  
      TokenPurchase(msg.sender, beneficiary, weiAmount, numTokens);
      
      // Put funds into owner's wallet immediately
      forwardFunds();
      
      // Update total wei amount raised, and total tokens obtained 
      // Using the SafeMath add() function!!!!!
      weiRaised = add(weiRaised, weiAmount);
      numTokensSold = add(numTokensSold, numTokens);
      
      
  }

  /**
   * Transfers accrued investments into owner's  wallet
   * I think we should be able to call this even after sale is over
   */
  function forwardFunds() internal {
    //
    wallet.transfer(msg.value);
    // It's internal so beneficiaries can't call it
  }
  
  /**
   * Ends the crowdsale once goalReached = true 
   */
  function endSale() internal {
      if (goalReached) {
          // HOW TO CLOSE A WALLET 
          // Should we call forwardFunds here so the owner gets all funds?
          // keep wallet open actually, so owner can receive funds after sale is over?
      }
  }

   /**
    * converts _weiAmount to its corresponding token amount  
    */
  function getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
    return _weiAmount.mul(rate);
    
    //uint256 weiAmount = msg.value;
    // calculate token amount to be created
    //uint256 tokens = weiAmount.mul(rate);
  }

  
  /**
   * To check whether goal has been reached (and whether we should end sale)
   */
  function isGoalReached() internal view returns (bool) {
      // Or should this be public so that investors can see how close to the goal we are?
      if (weiRaised >= goal) {
          goalReached = true;
      }
      return true;
  }
  
  
  /**
   * Allows investors to be refunded, as long as remaining time > 0
   */
  function refund() public {
    // Investors cannot be refunded after goal is reached
    require(!goalReached());
    uint256 currentTime = block.timestamp; // I'm sure there's a better/more accurate way of getting the ACTUAL time?
    require(currentTime <= endTime);
    require(currentTime >= startTime);
    
    // HOW DOES REFUNDING ACTUALLY HAPPEN
  }
  
  /**
   * Owner must be able to burn tokens not yet used. 
   * Returns true if successfully burned _amount tokens from total supply. 
   */
  function burnTokens(uint256 _amount) internal returns (bool) {
      require(_amount <= totalSupply);
      
      totalSupply = sub(totalSupply, _amount);
      return true;
  }
  
  /**
   * Owner must be able to mint new tokens. 
   * Returns true if successfully minted _amount tokens.
   */
  function burnTokens(uint256 _amount) internal returns (bool) {
      require(add(_amount, totalSupply) <= cap);
      
      totalSupply = add(totalSupply, _amount);
      return true;
  }
  
  /**
   * Fallback function 
   */
  function () external payable {
      buyTokens(msg.sender);
  }
  
}
