# Merkle Airdrop & Off-Chain Signature Verification

A high-performance, production-ready Ethereum token distribution system leveraging **EIP-712 structured data signing** and **Merkle Trees** for gas-optimized, cryptographic allocations. Built entirely within the Foundry framework.

---

## 🏗️ System Architecture

The protocol is split into two distinct security layers designed to eliminate unnecessary on-chain storage costs and prevent front-running attacks:

1. **The Merkle Layer (Allocation):** Instead of storing thousands of eligible addresses in persistent contract storage (which is violently expensive in gas), allocations are compiled into an off-chain Merkle Tree. Only a single 32-byte `ROOT` hash is stored on-chain.
2. **The Cryptographic Layer (Execution):** To claim tokens, a user provides a Merkle Proof matching the root. To prevent relayer front-running, the user signs an EIP-712 compliant digest off-chain. The processing script (Relayer) submits this signature to the contract, paying the gas on the user's behalf.

---

## 📦 EVM Storage Layout & Architecture

The state variables in this protocol are highly optimized to minimize storage slot overhead. The contract utilizes tight variable packing where possible to reduce `SSTORE` execution costs.

### State Variable Mapping
* **`ROOT` (`bytes32`):** Occupies 1 full storage slot (32 bytes). It represents the cryptographic anchor of the entire distribution tree.
* **`airdropToken` (`IERC20`):** Occupies 20 bytes (address size). 
* **`i_airdropSigner` (`address`):** Occupies 20 bytes. Represents the public identity authorized to validate off-chain claims.

---

## 📑 Supported Transaction Envelopes

Transactions interacting with this protocol are fully compatible with modern Ethereum transaction formats specified under the **EIP-2718 Typed Transaction Envelope** framework:

* **Type 0 (Legacy):** Standard raw RLP-encoded format utilizing a single `gasPrice` market.
* **Type 1 (EIP-2930):** Incorporates an explicit `accessList` to pre-warm contract addresses and storage slots, mitigating gas spikes introduced by EIP-2929.
* **Type 2 (EIP-1559):** The modern standard format featuring split gas metrics (`maxPriorityFeePerGas` and `maxFeePerGas`), utilizing the protocol's automatic `baseFee` burn mechanic for predictable pricing.

---

## 🚀 Setup & Local Deployment

### Prerequisites
Ensure you are using the standard "vanilla" nightly toolchain of Foundry. If you are using a specialized compilation environment, update your installation:
```bash
foundryup
1. Initialize the Testnet Node
Spin up a local, deterministic Ethereum node using Anvil to generate your pre-funded test accounts:

Bash
anvil
2. Configure Dependencies
Install the required system submodules. If Git caches conflict from previous installations, clear the staging index before running the download:

Bash
git rm -r --cached lib/foundry-devops 2>/dev/null
rm -rf lib/foundry-devops
forge install Cyfrin/foundry-devops
3. Smart Contract Deployment
To deploy the airdrop contracts and track the deployment artifacts using local DevOps tools, execute the deployment script against your running Anvil node:

Bash
forge script script/DeployMerkleAirDrop.s.sol --rpc-url $ANVIL_RPC --private-key $ANVIL_PRIVATE_KEY --broadcast
🛠️ Cryptographic Interaction Workflow
To claim tokens from the deployed architecture using raw command-line utilities, follow this cryptographic lifecycle sequence:

Step 1: Generate the EIP-712 Digest
Call the contract's read-only view function to compute the unique, context-specific bytes32 hash for a specific account and token allocation:

Bash
cast call <AIRDROP_CONTRACT_ADDRESS> "getMessage(address,uint256)" <CLAIMANT_ADDRESS> <CLAIM_AMOUNT> --rpc-url $ANVIL_RPC
Step 2: Sign the Digest Off-Chain
Take the resulting hash from Step 1 and sign it using the claimant's private key. The --no-hash flag is mandatory to prevent the tool from double-hashing an already calculated digest:

Bash
cast wallet sign --no-hash <MESSAGE_HASH> --private-key <CLAIMANT_PRIVATE_KEY>
Step 3: Execute the On-Chain Claim
Take the resulting 65-byte concatenated signature output, slice it into its native v, r, and s components, and populate the interaction script variables. Execute the transaction to claim your assets:

Bash
forge script script/Interact.s.sol:ClaimAirdrop --rpc-url $ANVIL_RPC --private-key <RELAYER_PRIVATE_KEY> --broadcast
🛡️ Security & Verification Mechanics
Signature Malleability Protection: The verification logic inside AirDrop.sol utilizes OpenZeppelin's audited ECDSA.tryRecover library, enforcing strict canonical checks on the s component of the elliptic curve point decompression to eliminate signature modification attacks.

Replay Attack Defense: The EIP-712 standard integration ensures that signatures are explicitly bound to the specific chainId and the contract's unique deployment address via the domainSeparator, preventing a signed voucher from being intercepted and replayed on other chains or protocol instances.