// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DeadManSwitch
 * @dev A smart contract that acts as a dead man switch.
 * The owner must call checkIn() periodically; if not, the beneficiary can claim the funds.
 */
contract DeadManSwitch {
    // State variables
    address public owner;
    address public beneficiary;
    uint256 public lastCheckIn;
    uint256 public timeout;

    // Events to log important contract actions
    event CheckIn(address indexed owner, uint256 timestamp);
    event Claimed(address indexed beneficiary, uint256 amount, uint256 timestamp);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);
    event TimeoutChanged(uint256 oldTimeout, uint256 newTimeout);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Constructor sets the initial beneficiary and timeout period.
     * @param _beneficiary The address that will receive funds if the owner fails to check in.
     * @param _timeout The period (in seconds) the owner has to check in before the beneficiary can claim.
     * The contract can also be deployed with Ether.
     */
    constructor(address _beneficiary, uint256 _timeout) payable {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_timeout > 0, "Timeout must be greater than 0");
        owner = msg.sender;
        beneficiary = _beneficiary;
        timeout = _timeout;
        lastCheckIn = block.timestamp;
    }

    // Modifier to restrict actions to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    /**
     * @dev Allows the owner to reset the dead man switch timer.
     * Emits a {CheckIn} event.
     */
    function checkIn() external onlyOwner {
        lastCheckIn = block.timestamp;
        emit CheckIn(owner, lastCheckIn);
    }

    /**
     * @dev Allows the beneficiary to claim the funds if the owner has not checked in within the timeout period.
     * Emits a {Claimed} event.
     */
    function claim() external {
        require(msg.sender == beneficiary, "Only beneficiary can claim funds");
        require(block.timestamp >= lastCheckIn + timeout, "Timeout period not reached");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to claim");

        // Transfer all the funds to the beneficiary
        (bool sent, ) = beneficiary.call{value: balance}("");
        require(sent, "Failed to send Ether");

        emit Claimed(beneficiary, balance, block.timestamp);
    }

    /**
     * @dev Allows the owner to update the beneficiary.
     * Emits a {BeneficiaryChanged} event.
     * @param _newBeneficiary The new beneficiary address.
     */
    function updateBeneficiary(address _newBeneficiary) external onlyOwner {
        require(_newBeneficiary != address(0), "Invalid beneficiary address");
        emit BeneficiaryChanged(beneficiary, _newBeneficiary);
        beneficiary = _newBeneficiary;
    }

    /**
     * @dev Allows the owner to update the timeout period.
     * Emits a {TimeoutChanged} event.
     * @param _newTimeout The new timeout period in seconds.
     */
    function updateTimeout(uint256 _newTimeout) external onlyOwner {
        require(_newTimeout > 0, "Timeout must be greater than 0");
        emit TimeoutChanged(timeout, _newTimeout);
        timeout = _newTimeout;
    }

    /**
     * @dev Allows the owner to transfer contract ownership.
     * Emits an {OwnerChanged} event.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Fallback function to accept incoming Ether transfers.
     */
    receive() external payable {}
}

// Jesus Loves You 
// John 3:16 
// Revelation 21:4 
