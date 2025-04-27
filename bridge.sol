// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AudioraBridgeBase {
    address public owner;
    IERC20 public audioraToken;

    // Mapping of processed nonces
    mapping(address => mapping(uint256 => bool)) public processedNonces;

    // Events
    event Locked(address indexed from, address indexed to, uint256 amount, uint256 date, uint256 nonce, string targetChain);
    event Released(address indexed to, uint256 amount, uint256 date, uint256 nonce);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        audioraToken = IERC20(_token);
    }

    function lockTokens(address _to, uint256 _amount, uint256 _nonce, string calldata _targetChain) external {
        require(!processedNonces[msg.sender][_nonce], "Transfer already processed");
        processedNonces[msg.sender][_nonce] = true;

        bool success = audioraToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        emit Locked(msg.sender, _to, _amount, block.timestamp, _nonce, _targetChain);
    }

    function releaseTokens(address _to, uint256 _amount, uint256 _nonce) external onlyOwner {
        require(!processedNonces[_to][_nonce], "Release already processed");
        processedNonces[_to][_nonce] = true;

        bool success = audioraToken.transfer(_to, _amount);
        require(success, "Token transfer failed");

        emit Released(_to, _amount, block.timestamp, _nonce);
    }

    // Emergency withdrawal function for the owner
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        bool success = audioraToken.transfer(owner, _amount);
        require(success, "Withdraw failed");
    }
}
