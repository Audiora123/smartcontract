// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract AudioraCommunityDAO {
    IERC20 public audioraToken;
    uint256 public proposalCount;
    uint256 public quorum; // Minimum number of votes needed
    uint256 public votingPeriod = 3 days;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public votes; // proposalId => voter => voted

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 weight);
    event ProposalExecuted(uint256 indexed id);

    constructor(address _audioraToken, uint256 _quorum) {
        audioraToken = IERC20(_audioraToken);
        quorum = _quorum;
    }

    modifier onlyTokenHolders() {
        require(audioraToken.balanceOf(msg.sender) > 0, "Not a token holder");
        _;
    }

    function createProposal(string memory _description) external onlyTokenHolders {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            voteCount: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            executed: false
        });

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function vote(uint256 _proposalId) external onlyTokenHolders {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime, "Voting hasn't started yet");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!votes[_proposalId][msg.sender], "Already voted");

        uint256 voterWeight = audioraToken.balanceOf(msg.sender);
        require(voterWeight > 0, "No voting power");

        proposal.voteCount += voterWeight;
        votes[_proposalId][msg.sender] = true;

        emit Voted(_proposalId, msg.sender, voterWeight);
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount >= quorum, "Not enough votes to execute");

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
        // Execution logic can be added here
    }

    // DAO owner can update quorum if needed
    function updateQuorum(uint256 _newQuorum) external {
        // Optional: restrict only to governance proposals or admin
        quorum = _newQuorum;
    }
}
