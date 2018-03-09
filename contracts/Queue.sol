pragma solidity ^0.4.15;

/**
 * @title Queue
 * @dev Data structure contract used in `Crowdsale.sol`
 * Allows buyers to line up on a first-in-first-out basis
 * See this example: http://interactivepython.org/courselib/static/pythonds/BasicDS/ImplementingaQueueinPython.html
 */

contract Queue {
	/* State variables */
	uint8 size = 5;
	uint8 numPeopleInQueue;
	uint256 timeLimit;
	uint256 timer;
	// Probably a much more elegant way of doing this
    mapping (uint8 => address) queuePosToAddress;
    mapping (address => uint8) queueAddressToPos;

    
	/* Add events */
    // Fired when someone's time limit is over and they are ejected from the front of the queue
    event EjectFront(address ejected);
    
	/* Add constructor */
	function Queue() public {
	    numPeopleInQueue = 0;
	    timer = 0;
	}

	/* Returns the number of people waiting in line */
	function qsize() constant returns(uint8) {
		return numPeopleInQueue;
	}

	/* Returns whether the queue is empty or not */
	function empty() constant returns(bool) {
		return (numPeopleInQueue == 0);
	}
	
	/* Returns the address of the person in the front of the queue */
	function getFirst() constant returns(address) {
		address first = queuePosToAddress[0];
		if (first != 0) {
		    // if first = 0, the item at this position in the queue hasn't been initialized yet
		    return first;
		}
	}
	
	/* Allows `msg.sender` to check their position in the queue */
	function checkPlace() constant returns(uint8) {
		return queueAddressToPos[msg.sender];
	}
	
	/* Allows anyone to expel the first person in line if their time
	 * limit is up
	 */
	function checkTime() {
	    if (timer >= timeLimit) {
	        dequeue();
	    }
	    
	}
	
	/* Removes the first person in line; either when their time is up or when
	 * they are done with their purchase
	 */
	function dequeue() {
		// TODO: manually go through and update each of the 5 values twice (once for each map)
		// So a disgusting total of 10 manual dictionary edits... yikes...
	}

	/* Places `addr` in the first empty position in the queue */
	function enqueue(address addr) {
		// TODO: check each position manually 
		// or could keep track of the first empty position as a variable?
		
	}
}
