LOGITRUST LOGISTICS ESCROW
===========================

1. PURPOSE
----------
This version redesigns the original single-page Logistics Escrow DApp into a clearer task-based interface.

The interface is divided into:
- Overview
- My Agreements
- Create Agreement
- Fund Escrow
- Milestones
- Transaction History
- Account

This prevents registration, agreement creation, funding, verification and history from being placed on one crowded page.

2. COMPLETED FRONTEND REQUIREMENTS
----------------------------------
User Registration and Authentication
- MetaMask is used as wallet authentication.
- A connected wallet can register as Shipper or Carrier.
- The role is read from the deployed smart contract.

Agreement Creation
- Carrier is selected from registered Carrier addresses discovered from UserRegistered blockchain events.
- No carrier address needs to be typed.
- Deadline is selected with + / - day controls instead of a Unix timestamp.
- Milestones are added/removed with + / - controls.
- Milestone checkpoint names use dropdowns.
- Milestone payout percentages must total 100%.
- The frontend converts the selected delivery timing to a Unix timestamp internally.
- The old JSON milestone input has been removed.

Funding Mechanism
- Agreement ID is a dropdown populated from the blockchain.
- Funding amount is automatically taken from the selected agreement's total value and is read-only.
- MetaMask signs the ETH transaction.
- Funds are sent to the deployed escrow smart contract.

Milestone & Payout Management
- Agreement ID is a dropdown.
- Milestone ID/index is a dropdown populated from the selected agreement.
- Completed milestones are disabled in the dropdown.
- Proof hash remains a text field because it represents the cryptographic evidence supplied by the verification process.
- The deployed smart contract handles the milestone payout.

Automatic Refund / Dispute Handling
- Agreement selection is a dropdown.
- The frontend calls requestRefund(agreementId).
- IMPORTANT: true automatic deadline-triggered refund behaviour is a smart-contract responsibility. The supplied frontend ABI exposes requestRefund(), but the Solidity source was not included with the uploaded file, so the frontend cannot independently guarantee the internal refund condition.
- If the deployed contract already checks the deadline and critical milestone condition inside requestRefund(), this UI supports that mechanism.
- If automatic execution without a user transaction is required, the Solidity contract must implement an appropriate deadline/automation mechanism (for example, an authorized automation service or another contract-triggered process).

Transaction History
- Smart-contract events are loaded with ethers.js queryFilter().
- The interface displays AgreementCreated, AgreementFunded, MilestoneVerified, PaymentReleased, RefundProcessed and UserRegistered events.
- The history is chronological and shows event details and block time.

3. DATABASE / DATA STORAGE
--------------------------
This DApp uses a blockchain-first data architecture.

Primary data store:
- Ethereum Sepolia
- LogisticsEscrow smart contract

On-chain data includes:
- Registered user wallets and roles
- Agreement participants
- Agreement value
- Deadline
- Escrow balance / released amount
- Milestone state
- Milestone percentage
- Proof hash
- Completion timestamp
- Contract events used for transaction history

There is intentionally no centralized SQL database in this frontend because the escrow and contract state are the system's financial source of truth.

Browser storage:
- No browser storage is used for financial records.
- Browser/local storage may be added later for harmless UI preferences only.

Recommended production architecture:
Frontend -> Backend/API indexer -> PostgreSQL/MongoDB (read model)
                    |
                    +-> Ethereum Sepolia smart contract

The off-chain database should be treated as a searchable cache/index, not as the authoritative source for escrow balances or payouts.

4. SYSTEM ARCHITECTURE
----------------------
[ User ]
   |
   v
[ Web Browser / VS Code Live Server ]
   |
   +--> HTML/CSS/JavaScript UI
   |
   +--> ethers.js
   |
   v
[ MetaMask ]
   |
   v
[ Ethereum Sepolia ]
   |
   v
[ LogisticsEscrow Smart Contract ]
   |
   +--> User registration
   +--> Agreement creation
   +--> Escrow funding
   +--> Milestone verification
   +--> Progressive payout
   +--> Refund condition
   +--> Contract state/events

Logical layers:
1. Presentation Layer
   - Responsive multi-page navigation
   - Forms, dropdowns, stepper controls
   - Dashboard and transaction history

2. Web3/Application Layer
   - ethers.js
   - Wallet connection
   - ABI interaction
   - Validation
   - Blockchain event reading

3. Smart Contract Layer
   - User roles
   - Agreements
   - Escrow funds
   - Milestones
   - Payouts
   - Refunds
   - Events

4. Data Layer
   - Ethereum smart contract storage is authoritative.
   - Optional PostgreSQL/MongoDB indexer can be added for production search/reporting.

5. Authentication
   - MetaMask wallet address acts as the user's blockchain identity.
   - No password database is required for the current DApp.

5. VS CODE LIVE SERVER
----------------------
The frontend can be run directly with VS Code Live Server.

Steps:
1. Install Visual Studio Code.
2. Install the "Live Server" extension.
3. Open the project folder in VS Code.
4. Make sure index.html is in the project root.
5. Right-click index.html.
6. Select "Open with Live Server".
7. The browser will open the local development URL, normally similar to:
   http://127.0.0.1:5500/index.html
8. Install MetaMask and connect it to Ethereum Sepolia.
9. Ensure the configured contract address is the deployed LogisticsEscrow contract.

Do not open index.html only by double-clicking it if Live Server is available. Using Live Server provides a consistent local HTTP development environment.

6. PROJECT FILES
----------------
index.html
- Redesigned responsive frontend.
- Contains HTML, CSS, JavaScript and the existing deployed contract ABI.
- Uses ethers.js 6.7.0 from jsDelivr.

README.txt
- Setup instructions, requirements mapping, database explanation and architecture.

SYSTEM_ARCHITECTURE.md
- Architecture diagram and component responsibilities.

7. CONTRACT CONFIGURATION
--------------------------
Configured contract:
0xf433f3ce9be6D90b33fC557b8238314B71824983

Network:
Ethereum Sepolia

If the contract is redeployed, update CONTRACT_ADDRESS in index.html and replace CONTRACT_ABI with the new deployed ABI.

8. IMPORTANT SMART-CONTRACT LIMITATION
--------------------------------------
The uploaded source contained the frontend and ABI, but not the Solidity implementation.

Therefore:
- The redesigned frontend can call the existing contract functions.
- It cannot change the actual escrow rules.
- Progressive payout depends on verifyMilestone() in the deployed contract.
- Refund eligibility depends on requestRefund() in the deployed contract.
- A genuinely automatic refund that occurs without a user submitting a transaction requires smart-contract support for an automated trigger.

Before final submission, test the deployed contract on Sepolia with:
1. Shipper registration.
2. Carrier registration.
3. Agreement creation.
4. Full escrow funding.
5. Milestone verification and payout.
6. Deadline/refund condition.
7. Transaction history.
