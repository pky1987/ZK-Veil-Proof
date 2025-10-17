// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVerifier} from "./Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "./IncrementalMerkleTree.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Veil is IncrementalMerkleTree, ReentrancyGuard {
    IVerifier public immutable i_verifier;
    uint256 public constant DENOMINATION = 0.001 ether;

    mapping(bytes32 => bool) public s_nullifierHashes;
    mapping(bytes32 => bool) public s_commitments;

    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHash, address relayer, uint256 fee);

    // Allow the contract to receive ETH
    receive() external payable {}

    error Veil__DepositValueMismatch(uint256 expected, uint256 actual);
    error Veil__PaymentFailed(address recipient, uint256 amount);
    error Veil__NotAlreadySpent(bytes32 nullifierHash);
    error Veil__UnknownRoot(bytes32 root);
    error Veil__InvalidWithdrawProof();
    error Veil__FeeExceedsDepositValue(uint256 expected, uint256 actual);
    error Veil__CommitmentAlreadyAdded(bytes32 commitment);
    error Veil__InvalidRecipient(address expected, address actual);

    constructor(IVerifier _verifier, Poseidon2 _hasher, uint32 _merkleTreeDepth)
        IncrementalMerkleTree(_merkleTreeDepth, _hasher)
    {
        i_verifier = _verifier;
    }

    function deposit(bytes32 _commitment) external payable nonReentrant {
        if (s_commitments[_commitment]) {
            revert Veil__CommitmentAlreadyAdded(_commitment);
        }
        if (msg.value != DENOMINATION) {
            revert Veil__DepositValueMismatch(DENOMINATION, msg.value);
        }
        s_commitments[_commitment] = true;

        uint32 insertedIndex = _insert(_commitment);

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function withdraw(address _recipient, bytes calldata _proof, bytes32[] memory _publicInputs)
        external
        nonReentrant
    {
        address payable recipient = payable(_recipient);
        bytes32 _root = _publicInputs[0];
        bytes32 _nullifierHash = _publicInputs[1];
        address expectedRecipient = address(uint160(uint256(_publicInputs[2])));

        if (expectedRecipient != _recipient) {
            revert Veil__InvalidRecipient(expectedRecipient, _recipient);
        }

        if (s_nullifierHashes[_nullifierHash]) {
            revert Veil__NotAlreadySpent(_nullifierHash);
        }

        if (!isKnownRoot(_root)) {
            revert Veil__UnknownRoot({root: _root});
        }

        if (!i_verifier.verify(_proof, _publicInputs)) {
            revert Veil__InvalidWithdrawProof();
        }
        s_nullifierHashes[_nullifierHash] = true;
        (bool success,) = _recipient.call{value: DENOMINATION}("");
        if (!success) {
            revert Veil__PaymentFailed({recipient: _recipient, amount: DENOMINATION});
        }
        emit Withdrawal(_recipient, _nullifierHash, address(0), 0);
    }
}
