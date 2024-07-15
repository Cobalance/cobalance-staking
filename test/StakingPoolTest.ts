import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MockCarbonCredit, MockCxtToken } from "../typechain-types";
import { expect } from "chai";
import sinon from "sinon";
import chai from "chai";
import sinonChai from "sinon-chai";
import { StakingPool } from "../typechain-types/contracts/StakingPool";
import { time } from "@nomicfoundation/hardhat-network-helpers";

chai.should();
chai.use(sinonChai);

describe("StakingPool", function () {
  let cxtToken: MockCxtToken;
  let carbonCredit: MockCarbonCredit;
  let stakingPool: StakingPool;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  const oneDay = 3600 * 24;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const MockCxtTokenFactory = await ethers.getContractFactory("MockCxtToken");
    cxtToken = (await MockCxtTokenFactory.deploy()) as MockCxtToken;
    await cxtToken.waitForDeployment();

    const MockCarbonCreditFactory = await ethers.getContractFactory("MockCarbonCredit");
    carbonCredit = (await MockCarbonCreditFactory.deploy()) as MockCarbonCredit;
    await carbonCredit.waitForDeployment();

    const StakingPoolFactory = await ethers.getContractFactory("StakingPool");
    stakingPool = (await StakingPoolFactory.deploy(cxtToken.getAddress(), carbonCredit.getAddress())) as StakingPool;
    await carbonCredit.waitForDeployment();
    await cxtToken.transfer(addr1, 1000);
    await cxtToken.transfer(addr2, 1000);
  });

  it("Should add carbon credits", async function () {
    expect(await stakingPool.addCarbonCredits(100)).to.emit(stakingPool, "CarbonCreditsAdded")
    expect(await stakingPool.totalCarbonCredits()).to.equal(100);
  });

  it("Should stake and withdraw", async function () {
    await expect(stakingPool.connect(addr1).stake(100)).to.emit(stakingPool, "Staked");
    expect((await stakingPool.getStake(addr1)).balance).to.equal(100);
    expect((await cxtToken.balanceOf(addr1))).to.equal(900);
    expect((await stakingPool.getStake(addr1)).transactions.length).to.equal(1);
    expect(await stakingPool.totalStaked()).to.equal(100);
    await expect(stakingPool.connect(addr1).withdraw(50)).to.emit(stakingPool, "Withdrawn");
    expect((await stakingPool.getStake(addr1)).balance).to.equal(50);
    expect((await cxtToken.balanceOf(addr1))).to.equal(950);
    expect((await stakingPool.getStake(addr1)).transactions.length).to.equal(2);
    expect(await stakingPool.totalStaked()).to.equal(50);
    expect((await stakingPool.getTransactions(addr1.address))[0][0]).to.equal(100);
    expect((await stakingPool.getTransactions(addr1.address))[0][2]).to.equal(0);
    expect((await stakingPool.getTransactions(addr1.address))[1][0]).to.equal(50);
    expect((await stakingPool.getTransactions(addr1.address))[1][2]).to.equal(1);
  });

  it("Should log transactions", async function () {
    await expect(stakingPool.connect(addr1).stake(100)).to.emit(stakingPool, "Staked");
    expect((await stakingPool.getTransactions(addr1.address))[0][0]).to.equal(100);
    expect((await stakingPool.getTransactions(addr1.address))[0][0]).to.equal(100);
  });

  it("Should count time", async function () {
    expect(stakingPool.timeCreated).to.not.equal(null);
    await time.increase(oneDay * 10);
    const stake = await stakingPool.stakes(owner);
  });

  it("Should create yield curve", async function () {
    expect(await stakingPool.stake(100)).to.emit(stakingPool, "Staked");
    expect(await stakingPool.addCarbonCredits(100)).to.emit(stakingPool, "CarbonCreditsAdded");
    expect(await stakingPool.totalCarbonCredits()).to.equal(100);
    expect(await stakingPool.addCarbonCredits(200)).to.emit(stakingPool, "CarbonCreditsAdded");
    expect(await stakingPool.totalCarbonCredits()).to.equal(300);
    expect((await stakingPool.getYields())[0][0]).to.equal(0);
    expect((await stakingPool.getYields())[1][0]).to.equal(27397260);
    expect((await stakingPool.getYields())[2][0]).to.equal(82191780);
    expect((await stakingPool.getYields())[1][1]).to.equal(273972);
    expect((await stakingPool.getYields())[2][1]).to.equal(821917);
  });

  it("Should calculate staking yield", async function () {
    await stakingPool.addCarbonCredits(1000);
    await stakingPool.stake(100);
    expect(await stakingPool.calculateStakeYield(owner.address)).to.equal(273972600);
    await time.increase(oneDay);
    await stakingPool.stake(100);
    expect(await stakingPool.calculateStakeYield(owner.address)).to.equal(547945200);
    await time.increase(oneDay);
    expect(await stakingPool.calculateStakeYield(owner.address)).to.equal(684931500);
    await time.increase(oneDay * 10);
    expect(await stakingPool.calculateStakeYield(owner.address)).to.equal(2054794500);
    //console.log(Number(await stakingPool.calculateStakeYield(owner.address)) / Number(10**8));
  });

  it("Should check owner verification", async function () {
    await expect(stakingPool.connect(addr1).addCarbonCredits(1)).to.be.revertedWith("Caller is not the owner");
    await expect(stakingPool.connect(addr1).removeCarbonCredits(1)).to.be.revertedWith("Caller is not the owner");
  });

  afterEach(function () {
    sinon.restore();
  });

});
