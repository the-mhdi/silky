// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "util/ReentrancyGuard.sol";
import "./MerkleTreeWithHistory.sol";
import "./deposit.sol";

abstract contract WithdrawContract is ReentrancyGuard,MerkleTreeWithHistory,DepositContract {
        
        uint256 public denomination;
        event Withdrawal (address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);
    function withdraw(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        bytes32 _root,
        bytes32 _nullifierHash,
        address _recipient,
        address _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant {
        require(_fee <= denomination, "Fee exceeds transfer value");
        require(!nullifierHashes[_nullifierHash], "The note has been already spent");
        require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
        require(
            verifier.verifyProof(
                _pA,
                _pB,
                _pC,
                [
                    uint256(_root),
                    uint256(_nullifierHash),
                    uint256(uint160(_recipient)),
                    uint256(uint160(_relayer)),
                    _fee,
                    _refund
                ]
            ),
            "Invalid withdraw proof"
        );

        nullifierHashes[_nullifierHash] = true;
        _processWithdraw(_recipient, _relayer, _fee, _refund);
        emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
    }

     function _processWithdraw(address _recipient, address _relayer, uint256 _fee, uint256 _refund) internal virtual;


}