// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title xInfinityVaultUSDT
 * @dev A decentralized investment protocol with the following features:
 * - 1% weekly ROI on all deposits in USDT BEP20
 * - 5-level referral system with bonuses (15%, 1%, 1%, 1%, 1%)
 * - No marketing fees
 * - Minimum deposit: 10 USDT
 * - Maximum 100 deposits per address
 * - Staked funds locked for 100 weeks (principal can be withdrawn after lock period)
 */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract xInfinityVaultUSDT is ReentrancyGuard {
    address public owner;
    IERC20 public constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955); // USDT BEP20 mainnet

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    // Sum of deposit principal that is still locked / not yet withdrawn via withdrawPrincipal().
    // ownerWithdraw() can never touch this amount, so user principal always stays redeemable.
    uint256 public totalLockedPrincipal;
    address[] public stakers;

    uint256 constant BONUS_LINES_COUNT = 5;
    uint256 constant PERCENT_DIVIDER = 100;
    uint256 constant LOCK_PERIOD = 100 weeks; // 100 weeks lock period
    uint256 constant MIN_DEPOSIT = 10 * 10**18; // 10 USDT
    uint256[BONUS_LINES_COUNT] public ref_bonuses = [15, 1, 1, 1, 1];

    struct Deposit {
        uint256 amount;
        uint256 time;
        uint256 withdrawn; // Track how much has been withdrawn
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256[5] structure;
    }

    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event OwnerWithdrawal(address indexed owner, uint256 amount);
    event PrincipalWithdrawn(address indexed addr, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Owner can only withdraw USDT that is not owed back to stakers as locked principal.
    // This prevents the owner from ever draining funds users are guaranteed to reclaim
    // after their lock period ends.
    function ownerWithdraw(uint256 amount) external onlyOwner noReentrant {
        uint256 contractBalance = USDT.balanceOf(address(this));
        require(contractBalance > totalLockedPrincipal, "No withdrawable balance");

        uint256 withdrawable = contractBalance - totalLockedPrincipal;
        require(amount <= withdrawable, "Amount exceeds withdrawable balance");

        require(USDT.transfer(owner, amount), "USDT transfer failed");
        emit OwnerWithdrawal(owner, amount);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = block.timestamp;
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;

            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);

            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(address _upline, uint256 amount) external noReentrant {
        require(amount >= MIN_DEPOSIT, "Minimum deposit amount is 10 USDT");

        Player storage player = players[msg.sender];

        if (player.deposits.length == 0) {
            stakers.push(msg.sender);
        }

        require(player.deposits.length < 100, "Max 100 deposits per address");

        require(USDT.transferFrom(msg.sender, address(this), amount), "USDT transfer failed");

        _setUpline(msg.sender, _upline, amount);

        player.deposits.push(Deposit({
            amount: amount,
            time: block.timestamp,
            withdrawn: 0
        }));

        player.total_invested += amount;
        invested += amount;
        totalLockedPrincipal += amount;

        _refPayout(msg.sender, amount);

        emit NewDeposit(msg.sender, amount);
    }

    function withdraw() external noReentrant {
        Player storage player = players[msg.sender];
        require(player.total_invested > 0, "Join first");

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        require(USDT.transfer(msg.sender, amount), "Withdrawal transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    // New function to withdraw principal after lock period
    function withdrawPrincipal(uint256 depositIndex) external noReentrant {
        Player storage player = players[msg.sender];
        require(depositIndex < player.deposits.length, "Invalid deposit index");

        Deposit storage dep = player.deposits[depositIndex];
        require(block.timestamp >= dep.time + LOCK_PERIOD, "Funds are still locked");
        require(dep.withdrawn == 0, "Principal already withdrawn");

        // Settle any dividends accrued up to now before this deposit stops earning.
        _payout(msg.sender);

        uint256 principal = dep.amount;
        dep.withdrawn = principal;
        totalLockedPrincipal -= principal;

        require(USDT.transfer(msg.sender, principal), "USDT transfer failed");
        emit PrincipalWithdrawn(msg.sender, principal);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

            // A deposit whose principal has already been withdrawn stops earning dividends.
            if(dep.withdrawn != 0) continue;

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp;

            if(from < to) {
                value += (dep.amount * (to - from) * 1) / (604800 * 100);
            }
        }

        return value;
    }

    // Updated userInfo to include lock status
    function userInfo(address _addr) view external returns(
        uint256 for_withdraw,
        uint256 total_invested,
        uint256 total_withdrawn,
        uint256 total_match_bonus,
        uint256[BONUS_LINES_COUNT] memory structure,
        uint256[] memory lockedPrincipals,
        uint256[] memory unlockTimes
    ) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        // Prepare locked principal data
        lockedPrincipals = new uint256[](player.deposits.length);
        unlockTimes = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
            if(player.deposits[i].withdrawn == 0) {
                lockedPrincipals[i] = player.deposits[i].amount;
                unlockTimes[i] = player.deposits[i].time + LOCK_PERIOD;
            }
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure,
            lockedPrincipals,
            unlockTimes
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

    function getTotalStakers() external view returns (uint256) {
        return stakers.length;
    }
}
