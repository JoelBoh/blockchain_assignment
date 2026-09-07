# BMIS2003 Blockchain Application Development
## Solving Problem 1
### 1. Decentralized Escrow and Milestone-Based Logistics Platform

Traditional supply chain logistics and trade finance heavily rely on centralized intermediaries,
paper-heavy documentation, and manual compliance checks, often leading to payment delays
and friction between shippers and carriers. A decentralized escrow platform leverages smart
contracts to lock funds securely on-chain and distribute them automatically to service providers
only when verifiable, immutable milestones are fulfilled.
Each team is to design and develop a decentralized application (dApp) using the Ethereum
platform and Solidity language that enables commercial parties to create, fund, and execute
milestone-based logistics agreements:
Requirements:
• User Registration and Authentication: Users should be able to register and log in to
the platform as either a Shipper (buyer) or a Carrier (service provider).
• Agreement Creation: Shippers should be able to create new logistics contracts with
details such as total payload value, required milestone checkpoints, and a strict delivery
deadline.
• Funding Mechanism: Shippers must be able to contribute cryptocurrency (e.g., Ether)
to lock the contract funds into the escrow smart contract upon initialization.
• Milestone & Payout Management: Payments must be securely held on-chain and
automatically released progressively (e.g., partial payment on pickup, balance on final
delivery) to the Carrier based on cryptographic verification of milestone completions.

• Automatic Refunds / Dispute Handling: If a Carrier fails to meet a critical milestone
within the deadline, the smart contract should automatically trigger a refund mechanism
back to the Shipper.
• Transaction History: Users should be able to view their contract participation, current
escrow balances, and chronological milestone history.
For this assignment:
• You may define a token standard (e.g., ERC-20) to represent carrier reputation points
or service stakes awarded upon successful milestone completions.
• You need to define the relationship between contract funds and milestone distributions
(e.g., "30% released upon Milestone 1 verification").
• It is mandatory to integrate the user interface with the smart contracts. If the project is
presented solely in Remix, it will be considered incomplete.
