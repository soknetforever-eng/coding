// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// ============================================================================
/// EDUCATIONAL / TESTNET CONTRACT — NOT AUDITED — NOT FOR REAL DEPOSITS
///
/// This contract pays a fixed 10% per month "interest" out of the SAME pool
/// that deposits sit in. There is no external yield source, so it is
/// economically a zero-sum (in fact negative-sum, after gas) pool:
///
///   - It is solvent only as long as new deposits >= interest owed to
///     existing depositors. As soon as inflows slow down, later
///     depositors cannot be paid — this is the exact mechanism of a
///     Ponzi / high-yield-investment-program (HYIP) scheme.
///   - 10%/month compounds to roughly 213% APY, which no legitimate,
///     sustainable on-chain strategy currently produces risk-free.
///   - `withdraw` will simply revert once the contract's USDT balance
///     is exhausted, leaving remaining depositors unable to exit.
///
/// This file exists to demonstrate deposit/withdraw/interest-accrual
/// mechanics for learning purposes (testnets, unit tests, code review).
/// Do NOT deploy this to mainnet and market it to real depositors as an
/// investment product — that would defraud whoever deposits after the
/// pool can no longer cover obligations. If you want a real yield
/// product, the interest must be funded from a genuine external source
/// (protocol revenue, a fixed-supply reward budget the owner tops up and
/// that pays 0% once exhausted, etc.), not from later depositors' principal.
/// ============================================================================
contract USDTStakingPool is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice BEP20 USDT token this pool accepts.
    IERC20 public immutable usdt;

    /// @notice Interest rate in basis points per 30-day month (1000 = 10%).
    uint256 public constant MONTHLY_RATE_BPS = 1000;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant SECONDS_PER_MONTH = 30 days;

    /// @notice Principal + settled (compounded) interest per depositor.
    mapping(address => uint256) public balanceOf;
    /// @notice Timestamp interest was last settled for a depositor.
    mapping(address => uint256) public lastSettledAt;

    uint256 public totalDeposited;

    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed user, uint256 amount, uint256 newBalance);
    event InterestSettled(address indexed user, uint256 interestAccrued, uint256 newBalance);

    constructor(address usdtToken, address initialOwner) Ownable(initialOwner) {
        require(usdtToken != address(0), "usdt: zero address");
        usdt = IERC20(usdtToken);
    }

    /// @notice Deposit `amount` USDT. Caller must have approved this contract first.
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "amount must be > 0");

        _settleInterest(msg.sender);

        usdt.safeTransferFrom(msg.sender, address(this), amount);

        balanceOf[msg.sender] += amount;
        totalDeposited += amount;

        emit Deposited(msg.sender, amount, balanceOf[msg.sender]);
    }

    /// @notice Withdraw `amount` (principal + any settled interest) back to the caller.
    /// @dev Reverts if the pool's USDT balance can't cover the withdrawal — see the
    /// solvency warning at the top of this file.
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "amount must be > 0");

        _settleInterest(msg.sender);

        uint256 bal = balanceOf[msg.sender];
        require(amount <= bal, "amount exceeds balance");
        require(amount <= usdt.balanceOf(address(this)), "pool has insufficient liquidity");

        balanceOf[msg.sender] = bal - amount;
        if (totalDeposited >= amount) {
            totalDeposited -= amount;
        } else {
            totalDeposited = 0;
        }

        usdt.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount, balanceOf[msg.sender]);
    }

    /// @notice Withdraw the caller's full balance (principal + accrued interest).
    function withdrawAll() external {
        _settleInterest(msg.sender);
        uint256 bal = balanceOf[msg.sender];
        require(bal > 0, "nothing to withdraw");
        // Reuse withdraw() logic via an external call is avoided for gas/clarity;
        // instead call the internal path directly.
        _withdrawInternal(msg.sender, bal);
    }

    function _withdrawInternal(address user, uint256 amount) private nonReentrant {
        require(amount <= usdt.balanceOf(address(this)), "pool has insufficient liquidity");

        balanceOf[user] -= amount;
        if (totalDeposited >= amount) {
            totalDeposited -= amount;
        } else {
            totalDeposited = 0;
        }

        usdt.safeTransfer(user, amount);

        emit Withdrawn(user, amount, balanceOf[user]);
    }

    /// @notice View pending interest for `user` without settling it on-chain.
    function pendingInterest(address user) public view returns (uint256) {
        uint256 principal = balanceOf[user];
        if (principal == 0) return 0;

        uint256 lastUpdate = lastSettledAt[user];
        if (lastUpdate == 0 || block.timestamp <= lastUpdate) return 0;

        uint256 elapsed = block.timestamp - lastUpdate;
        return (principal * MONTHLY_RATE_BPS * elapsed) / (BPS_DENOMINATOR * SECONDS_PER_MONTH);
    }

    /// @notice Total balance (principal + unsettled interest) for `user`.
    function totalBalanceOf(address user) external view returns (uint256) {
        return balanceOf[user] + pendingInterest(user);
    }

    /// @dev Compounds any pending interest for `user` into their principal.
    function _settleInterest(address user) private {
        uint256 interest = pendingInterest(user);
        if (interest > 0) {
            balanceOf[user] += interest;
            emit InterestSettled(user, interest, balanceOf[user]);
        }
        lastSettledAt[user] = block.timestamp;
    }

    /// @notice Owner can top up the pool's USDT reserve (does not credit any balance).
    /// @dev Useful for testing scenarios where the pool needs liquidity to pay interest.
    function fundPool(uint256 amount) external {
        require(amount > 0, "amount must be > 0");
        usdt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Pause deposits (existing depositors can still withdraw). Owner only.
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Current USDT balance held by the contract.
    function poolLiquidity() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }
}
