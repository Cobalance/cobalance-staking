// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/IERC20.sol";
import "./ERC3643/IERC3643.sol";

contract StakingPool {

    IERC20 public CXT;
    IERC3643 public carbonCredit;

    uint256 private constant DECIMALS = 8;

    struct Yield {
        uint256 value;
        uint256 valuePerToken;
        uint256 time;
    }

    enum TransactionType {
        Stake,
        Withdraw
    }

    struct Transaction {
        uint256 amount;
        uint256 time;
        TransactionType transactionType;
        uint256 balanceAsOf;
    }

    struct Stake {
        Transaction[] transactions;
        uint256 balance;
    }

    struct PoolData {
        uint256 totalCarbonCredits;
        uint256 totalCxt;
        uint256 yieldPerCxt;
        uint256 daysStaked;
        uint256 reward;
        uint256 stakedCxt;
    }

    uint256 public timeCreated;
    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public totalCarbonCredits;
    Yield[] public yields;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 cxtAmount, uint256 carbonCreditAmount);
    event CarbonCreditsAdded(uint256 amount);
    event CarbonCreditsRemoved(uint256 amount);
    event YieldUpdated(uint256 amount);

    constructor(address cxtAddress, address carbonCreditAddress) {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        CXT = IERC20(cxtAddress);
        carbonCredit = IERC3643(carbonCreditAddress);
        timeCreated = block.timestamp;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");

        CXT.transferFrom(msg.sender, address(this), amount);

        stakes[msg.sender].balance += amount;
        stakes[msg.sender].transactions.push(Transaction({
          amount: amount,
          time: block.timestamp,
          transactionType: TransactionType.Stake,
          balanceAsOf: stakes[msg.sender].balance
        }));

        totalStaked += amount;
        _calculateYield();

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0 tokens");
        require(stakes[msg.sender].balance >= amount, "Insufficient staked amount");

        uint256 yieldBefore = this.calculateStakeYield(msg.sender);

        stakes[msg.sender].balance -= amount;
        stakes[msg.sender].transactions.push(Transaction({
          amount: amount,
          time: block.timestamp,
          transactionType: TransactionType.Withdraw,
          balanceAsOf: stakes[msg.sender].balance
        }));
        totalStaked -= amount;

        CXT.transfer(msg.sender, amount);

        uint256 yieldAfter = this.calculateStakeYield(msg.sender);
        uint256 yieldToWithdraw = yieldBefore - yieldAfter;
        carbonCredit.transfer(msg.sender, yieldToWithdraw);

        _calculateYield();

        emit Withdrawn(msg.sender, amount, yieldToWithdraw);
    }

    function addCarbonCredits(uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot add 0 carbon credits");
        carbonCredit.transferFrom(msg.sender, address(this), amount);
        totalCarbonCredits += amount;

        _calculateYield();

        emit CarbonCreditsAdded(amount);
    }

    function removeCarbonCredits(uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot remove 0 carbon credits");
        carbonCredit.transferFrom(address(this), msg.sender, amount);
        totalCarbonCredits -= amount;

        _calculateYield();

        emit CarbonCreditsRemoved(amount);
    }

    function getStake(address account) public view returns (Stake memory) {
        return stakes[account];
    }

    function getYields() public view returns (Yield[] memory) {
        return yields;
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    function getTransactions(address account) public view returns (Transaction[] memory) {
        return stakes[account].transactions;
    }

    function calculateStakeYield(address account) public view returns (uint256) {
        uint256 totalYield = 0;
        Stake memory yieldStake = stakes[account];
        Transaction[] memory transactions = yieldStake.transactions;
        if (transactions.length == 0) return 0;
        uint256 currentTime = transactions[0].time;
        uint256 transactionAmount = 0;
        uint256 lastYieldIndex = 0;
        while(currentTime <= block.timestamp) {
            Yield memory applicableYield = _getMostRecentYield(currentTime, lastYieldIndex);
            for (uint256 i = 0; i < transactions.length; i++) {
                if (transactions[i].time <= currentTime) {
                    transactionAmount = transactions[i].amount;
                } else {
                    break;  
                }
            }
            if (applicableYield.time > 0) {
                totalYield += transactionAmount * applicableYield.valuePerToken;
            }
            currentTime += 1 days;
        }
        return totalYield;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getPoolData(address account) public view returns (PoolData memory) {
        uint256 yield = (totalCarbonCredits* 10**DECIMALS) / 365;
        uint256 yieldPerToken = totalStaked != 0 ? yield / totalStaked : 0;
        return PoolData({
            totalCarbonCredits: totalCarbonCredits,
            totalCxt: totalStaked,
            yieldPerCxt: yieldPerToken,
            daysStaked: 0,
            reward: calculateStakeYield(account),
            stakedCxt: stakes[account].balance
        });
    }

    function _getMostRecentYield(uint256 time, uint256 startFromIndex) internal view returns (Yield memory) {
        for (uint256 i = startFromIndex; i < yields.length; i++) {
            if (yields[i].time > time) {
                return yields[i - 1];
            }
        }
        return yields[yields.length - 1];
    }

    function _calculateYield() internal {
        uint256 yield = (totalCarbonCredits* 10**DECIMALS) / 365;
        uint256 yieldPerToken = totalStaked != 0 ? yield / totalStaked : 0;
        yields.push(Yield({
            value: yield,
            valuePerToken: yieldPerToken,
            time: block.timestamp            
        }));
        emit YieldUpdated(yield);
    }
}
