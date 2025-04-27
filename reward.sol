// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract RewardDistributor {

    address public owner;
    IERC20 public rewardToken;

    mapping(address => uint256) public rewards; // user address => reward amount

    event RewardDeposited(address indexed depositor, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardAssigned(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        rewardToken = IERC20(0xC76B4D831ad4225e09E986D82bd8853a41CF402B);
    }

    // Owner can deposit rewards into the contract
    function depositRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        rewardToken.transferFrom(msg.sender, address(this), amount);
        emit RewardDeposited(msg.sender, amount);
    }

    // Owner assigns rewards to a user
    function assignReward(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        rewards[user] += amount;
        emit RewardAssigned(user, amount);
    }

    // Users claim their rewards
    function claimReward() external {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient reward balance");

        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, amount);

        emit RewardClaimed(msg.sender, amount);
    }

    // Emergency withdrawal by owner (in case needed)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(owner, balance);
    }
}
