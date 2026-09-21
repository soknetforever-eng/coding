# USDT (BEP20) Staking Pool — 10%/month interest

**Educational / testnet project.** This is a Solidity contract for BNB Smart
Chain that lets users deposit BEP20 USDT and later withdraw their principal
plus 10% interest per 30-day month, compounding continuously while a
position sits in the pool.

## ⚠️ Read this before deploying anywhere real

Interest here is paid **out of the same pool that deposits sit in** — there
is no external yield source (no lending, no LP fees, no protocol revenue).
That means:

- The pool is solvent only as long as incoming deposits outpace interest
  owed to existing depositors. This is the same mechanism as a Ponzi /
  high-yield-investment-program (HYIP) scheme.
- 10%/month compounds to roughly **213% APY**, far beyond what any
  sustainable, risk-free on-chain strategy currently produces.
- `withdraw()` / `withdrawAll()` will simply revert with `"pool has
  insufficient liquidity"` once the contract's USDT balance runs out,
  leaving remaining depositors unable to exit.

This repo exists to demonstrate deposit/withdraw/interest-accrual mechanics
for learning, code review, and testnet experimentation — see the
`reverts a withdrawal when the pool lacks liquidity` test for a concrete
demonstration of the insolvency case. **Do not deploy this to mainnet and
market it to real depositors as an investment product.** If you want a real
yield product, interest needs to be funded from a genuine external source
(protocol revenue, or a fixed reward budget the owner tops up that pays 0%
once exhausted), not from later depositors' principal.

## Contract

[`contracts/USDTStakingPool.sol`](contracts/USDTStakingPool.sol)

- `deposit(uint256 amount)` — pulls `amount` USDT from the caller (requires
  a prior `approve`) and credits it to their balance. Any interest already
  accrued is settled (compounded into principal) first.
- `withdraw(uint256 amount)` — settles accrued interest, then sends
  `amount` USDT back to the caller. Reverts if `amount` exceeds the
  caller's balance or the pool's on-hand USDT.
- `withdrawAll()` — withdraws the caller's full balance (principal +
  accrued interest).
- `pendingInterest(address user)` / `totalBalanceOf(address user)` — view
  functions to inspect accrued interest without submitting a transaction.
- `fundPool(uint256 amount)` — anyone can top up the contract's USDT
  reserve (e.g. for testing withdrawal scenarios); it does not credit a
  balance to the funder.
- `pause()` / `unpause()` (owner only) — stops new deposits; existing
  depositors can still withdraw while paused.

Interest math: `interest = principal * 1000 bps * elapsedSeconds / (10_000 * 30 days)`,
i.e. a fixed 10% every 30 days, prorated linearly by elapsed time and
compounded into principal each time a user deposits, withdraws, or their
pending interest is queried on-chain.

Built with OpenZeppelin v5 (`SafeERC20`, `Ownable`, `ReentrancyGuard`,
`Pausable`) for standard safe-transfer and reentrancy protections.

## Project layout

```
contracts/
  USDTStakingPool.sol   # main contract
  mocks/MockUSDT.sol    # mintable ERC20 stand-in for USDT, used in tests
test/
  USDTStakingPool.test.js
scripts/
  deploy.js
```

## Usage

```bash
npm install
npx hardhat compile
npx hardhat test
```

### Deploying to BSC testnet

```bash
export DEPLOYER_PRIVATE_KEY=0x...           # testnet key, funded with tBNB
export USDT_ADDRESS=0x...                   # omit to auto-deploy MockUSDT instead
npx hardhat run scripts/deploy.js --network bsctestnet
```

BSC mainnet USDT (BEP20) address, for reference: `0x55d398326f99059fF775485246999027B3197955`.
This project intentionally does not ship a mainnet deploy script/network —
see the warning above.
