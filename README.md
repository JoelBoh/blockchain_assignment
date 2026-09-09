# 🚚 Logistics Escrow Platform

A decentralized, milestone-based escrow system for shipping and logistics agreements, built on Ethereum. Shippers lock funds into a smart contract up front, and carriers get paid automatically as each delivery milestone is verified on-chain — no third party holding the money in between.

Built for **BMIS2003 Blockchain Application Development**.

## How it works

A shipper registers, then creates an agreement with a chosen carrier, a total value in ETH, a deadline, and a list of milestones (e.g. Pickup, In Transit, Delivered), each with a percentage of the total payout. The shipper funds the agreement with the exact ETH amount. As the carrier completes each milestone and submits proof, the corresponding percentage of funds is released to them automatically. If something goes wrong before all milestones are done, the shipper can request a refund of whatever hasn't been released yet.

## Tech stack

- **Solidity** (`^0.8.0`) — the escrow contract itself
- **Ethereum Sepolia testnet** — deployment network
- **ethers.js v6** — contract interaction from the browser
- **MetaMask** — wallet connection
- **Plain HTML/CSS/JS** — single-page frontend, no build step required

## Project structure

```
.
├── LogisticsEscrow.sol           # Smart contract
├── logistics-escrow-platform.html # Frontend dApp
└── README.md
```

## Smart contract

`LogisticsEscrow.sol` handles:

- **User registration** — addresses register as either `Shipper` or `Carrier` before doing anything else
- **Agreement creation** — shipper defines a carrier, total value, deadline, and milestone list (percentages must sum to 100)
- **Escrow funding** — shipper sends the exact agreed ETH amount to lock it in the contract
- **Milestone verification** — carrier submits a proof hash per milestone; the contract releases that milestone's share of funds automatically
- **Refunds** — shipper can reclaim whatever remains unreleased if the agreement isn't complete

State is tracked per-agreement through a `Stage` enum (`Init → Funded → InProgress → Completed`, or `Refunded`), and every action emits an event (`AgreementCreated`, `AgreementFunded`, `MilestoneVerified`, `PaymentReleased`, `RefundProcessed`, `UserRegistered`) for the frontend's transaction history.

### Deployed contract (Sepolia)

```
0xf433f3ce9be6D90b33fC557b8238314B71824983
```

View it on [Sepolia Etherscan](https://sepolia.etherscan.io/address/0xf433f3ce9be6D90b33fC557b8238314B71824983).

## Running the frontend

1. Make sure [MetaMask](https://metamask.io/) is installed and switched to the **Sepolia** test network.
2. Get some Sepolia test ETH from a faucet (e.g. [sepoliafaucet.com](https://sepoliafaucet.com/)) if you don't have any.
3. Open `logistics-escrow-platform.html` directly in a browser (double-click, or serve it with any static file server).
4. Click **Connect Wallet** and approve the connection in MetaMask.

If you redeploy the contract yourself, update the `CONTRACT_ADDRESS` constant near the top of the `<script>` block in the HTML file to match your new deployment.

## Using the dApp

**Register** — pick a role (Shipper or Carrier) and register your connected address. You need a second MetaMask account registered as the opposite role to test a full agreement end-to-end, since a shipper can't be their own carrier.

**Create Agreement** — enter the carrier's address (must already be registered as Carrier), the total ETH value, a Unix deadline timestamp, and a JSON array of milestones. Example:

```json
[
  {"text": "Pickup", "percentage": 30},
  {"text": "In Transit", "percentage": 30},
  {"text": "Delivered", "percentage": 40}
]
```

Percentages must add up to 100.

**Fund Escrow** — as the shipper, send the exact total value for a given agreement ID.

**Verify Milestone** — as the carrier, mark a milestone complete with a proof hash. Payment for that milestone releases immediately.

**Request Refund** — as the shipper, reclaim any unreleased funds if the agreement isn't yet complete.

**View Agreement** — look up any agreement by ID to see its current state, amounts released/paid, and milestone progress.

The dashboard and transaction history at the bottom of the page refresh automatically after each action, or on demand via the **Refresh** button.

## Notes

- All amounts are entered and displayed in ETH; the contract itself works in wei.
- This is a testnet project for coursework — not audited, and not intended for mainnet use as-is.
