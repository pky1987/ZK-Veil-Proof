use poseidon::poseidon2;
mod merkle_tree;

fn main(
    // Public inputs (must match NUMBER_OF_PUBLIC_INPUTS in Verifier.sol)
    root: pub Field,
    nullifier_hash: pub Field,
    recipient: pub Field,


    // Private inputs
    nullifier: Field,
    secret: Field,
    merkle_proof: [Field; 20],
    is_even: [bool; 20],
) {
    let commitment = poseidon2::Poseidon2::hash([nullifier, secret], 2);
    let computed_nullifier_hash = poseidon2::Poseidon2::hash([nullifier], 1);
    
    assert(computed_nullifier_hash == nullifier_hash, "Invalid nullifier hash");
    
    let computed_root = merkle_tree::compute_merkle_root(commitment, merkle_proof, is_even);
    assert(computed_root == root, "Invalid merkle root");
}