import { Barretenberg, Fr } from "@aztec/bb.js";
import { ethers } from "ethers";

export default async function generateCommitment(): Promise<string> {
  const bb = await Barretenberg.new();

  // generate nullifier
  const nullifier = Fr.random();

  // generate secret
  const secret = Fr.random();

  // create commitment
  const commitment: Fr = await bb.poseidon2Hash([nullifier, secret]);

  const result = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32", "bytes32", "bytes32"],
    [commitment.toBuffer(), nullifier.toBuffer(), secret.toBuffer()]
  );

  return result;
}

(async () => {
  generateCommitment()
  .then((result) => {
    process.stdout.write(result);
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
})();