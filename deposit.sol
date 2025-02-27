// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "util/ReentrancyGuard.sol";
import "./MerkleTreeWithHistory.sol";

//EOA deposits, AA withdrawals)//

abstract contract DepositContract is ReentrancyGuard, MerkleTreeWithHistory{
      // --- Storage ---
    address public paymasterContract; // Address of the Gas Contract
    uint256 public constant prepaied_withdrawl_gasfee = 1; // Fixed gas escrow amount (adjust as needed)
    address public feeContract;
    uint256 public constant poolFee = 1 ;
    mapping(bytes32 => bool) public commitments; // we store all commitments just to prevent accidental deposits with the same commitment
    mapping (bytes32 => bool) public nullifierHashes;
    
     

 // --- Events ---
    event Deposit(bytes32 indexed commitment, uint32 index, uint256 amount, uint256 timestamp);

// --- Constructor ---
    constructor(address _paymasterContract, address _feeContract) {
        paymasterContract = _paymasterContract;
        feeContract = _feeContract;
    }

 // --- functions ---
    // --- Deposit ETH Function ---
function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");
    
    //  Store Commitment
    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    // 3. Escrow Gas to Gas Contract
      (bool success, ) = paymasterContract.call{value: prepaied_withdrawl_gasfee}(""); // Sending ETH to paymaster Contract
      require(success, "Sending ETH to paymaster Contract failed");
      
      (bool feeSuccess, ) = feeContract.call{value: poolFee}("");
      require(feeSuccess, "failed paying pool fee");

    _processDeposit();

    emit Deposit(_commitment, insertedIndex,msg.value, block.timestamp);
  }

  function _processDeposit() internal virtual;  

  
}

