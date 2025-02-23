// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "util/ReentrancyGuard.sol";
import "./MerkleTreeWithHistory.sol";

abstract contract DepositContract is ReentrancyGuard, MerkleTreeWithHistory{
      // --- Storage ---
    address public gasContractAddress; // Address of the Gas Contract
    uint256 public constant GAS_ESCROW_AMOUNT = 1; // Fixed gas escrow amount (adjust as needed)
    mapping(bytes32 => bool) public commitments; // we store all commitments just to prevent accidental deposits with the same commitment
    mapping (bytes32 => bool) nullifierHashes;

 // --- Events ---
    event Deposit(bytes32 indexed commitment, uint32 index, uint256 amount, uint256 timestamp);

// --- Constructor ---
    constructor(address _gasContractAddress) {
        gasContractAddress = _gasContractAddress;
    }

 // --- functions ---
    // --- Deposit ETH Function ---
function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");
    
    //  Store Commitment
    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    // 3. Escrow Gas to Gas Contract
      (bool success, ) = gasContractAddress.call{value: GAS_ESCROW_AMOUNT}(""); // Sending ETH to Gas Contract
      require(success, "Gas escrow transfer failed");

    _processDeposit();

    emit Deposit(_commitment, insertedIndex,msg.value, block.timestamp);
  }

  function _processDeposit() internal virtual;  

  
}

