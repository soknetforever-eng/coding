const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const DAY = 24 * 60 * 60;
const MONTH = 30 * DAY;

describe("USDTStakingPool", function () {
  async function deployFixture() {
    const [owner, alice, bob] = await ethers.getSigners();

    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    const usdt = await MockUSDT.deploy();

    const Pool = await ethers.getContractFactory("USDTStakingPool");
    const pool = await Pool.deploy(await usdt.getAddress(), owner.address);

    const amount = ethers.parseUnits("1000", 18);
    await usdt.mint(alice.address, amount);
    await usdt.mint(bob.address, amount);
    // Fund the pool's reserve so it can pay out interest in tests.
    await usdt.mint(owner.address, ethers.parseUnits("1000000", 18));
    await usdt.connect(owner).approve(await pool.getAddress(), ethers.parseUnits("1000000", 18));
    await pool.connect(owner).fundPool(ethers.parseUnits("1000000", 18));

    return { pool, usdt, owner, alice, bob, amount };
  }

  it("accepts a deposit and tracks the balance", async function () {
    const { pool, usdt, alice, amount } = await deployFixture();

    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await expect(pool.connect(alice).deposit(amount))
      .to.emit(pool, "Deposited")
      .withArgs(alice.address, amount, amount);

    expect(await pool.balanceOf(alice.address)).to.equal(amount);
    expect(await pool.totalDeposited()).to.equal(amount);
  });

  it("accrues ~10% interest after one month", async function () {
    const { pool, usdt, alice, amount } = await deployFixture();

    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await pool.connect(alice).deposit(amount);

    await time.increase(MONTH);

    const pending = await pool.pendingInterest(alice.address);
    const expected = (amount * 1000n) / 10000n; // 10%
    // Allow small rounding tolerance from block timestamp drift.
    expect(pending).to.be.closeTo(expected, expected / 1000n);
  });

  it("lets a user withdraw principal plus accrued interest", async function () {
    const { pool, usdt, alice, amount } = await deployFixture();

    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await pool.connect(alice).deposit(amount);

    await time.increase(MONTH);

    const before = await usdt.balanceOf(alice.address);
    await pool.connect(alice).withdrawAll();
    const after = await usdt.balanceOf(alice.address);

    const received = after - before;
    const expectedMin = amount + (amount * 995n) / 10000n; // ~9.95%+ to allow drift
    expect(received).to.be.gt(expectedMin);
  });

  it("reverts a withdrawal larger than the caller's balance", async function () {
    const { pool, usdt, alice, amount } = await deployFixture();

    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await pool.connect(alice).deposit(amount);

    await expect(
      pool.connect(alice).withdraw(amount * 2n)
    ).to.be.revertedWith("amount exceeds balance");
  });

  it("reverts a withdrawal when the pool lacks liquidity", async function () {
    const [owner, alice] = await ethers.getSigners();
    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    const usdt = await MockUSDT.deploy();
    const Pool = await ethers.getContractFactory("USDTStakingPool");
    const pool = await Pool.deploy(await usdt.getAddress(), owner.address);

    const amount = ethers.parseUnits("1000", 18);
    await usdt.mint(alice.address, amount);
    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await pool.connect(alice).deposit(amount);

    // No pool funding beyond alice's own principal; interest owed can't be paid.
    await time.increase(MONTH);

    await expect(pool.connect(alice).withdrawAll()).to.be.revertedWith(
      "pool has insufficient liquidity"
    );
  });

  it("blocks deposits while paused but still allows withdrawals", async function () {
    const { pool, usdt, owner, alice, amount } = await deployFixture();

    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await pool.connect(alice).deposit(amount);

    await pool.connect(owner).pause();

    await usdt.mint(alice.address, amount);
    await usdt.connect(alice).approve(await pool.getAddress(), amount);
    await expect(pool.connect(alice).deposit(amount)).to.be.revertedWithCustomError(
      pool,
      "EnforcedPause"
    );

    await expect(pool.connect(alice).withdraw(amount)).to.not.be.reverted;
  });
});
