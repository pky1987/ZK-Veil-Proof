Libraries:

```
npm install ethers fs @aztec/bb.js@0.82.8 @noir-lang/noir_js@1.0.0-beta.3
```

For Circuit Cryptographic Proof Verifier:

```
nargo compile
```
```
bb write_vk --oracle_hash keccak -b ./target/circuits.json -o ./target
```
```
bb write_solidity_verifier -k ./target/vk -o ./target/Verifier.sol
```
