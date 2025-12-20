// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Polymarket Clone
/// @notice A decentralized prediction market contract allowing users to bet on outcomes
contract Polymarket {
    address public owner;
    address public polyToken;

    uint256 public totalQuestions = 0;

    /// @notice Initializes the contract
    /// @param _polyToken The address of the PolyToken contract used for betting
    constructor(address _polyToken) {
        owner = msg.sender;
        polyToken = _polyToken;
    }

    mapping(uint256 => Questions) public questions;

    /// @notice Structure to hold question details
    struct Questions {
        uint256 id;
        string question;
        uint256 timestamp;
        uint256 endTimestamp;
        address createdBy;
        string creatorImageHash;
        AmountAdded[] yesCount;
        AmountAdded[] noCount;
        uint256 totalAmount;
        uint256 totalYesAmount;
        uint256 totalNoAmount;
        bool eventCompleted;
        string description;
        string resolverUrl;
    }

    /// @notice Structure to hold bet details
    struct AmountAdded {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    // New mapping to store claimable balances
    mapping(address => uint256) public claimableWinnings;

    /// @notice Event emitted when a new question is created
    event QuestionCreated(
        uint256 id,
        string question,
        uint256 timestamp,
        address createdBy,
        string creatorImageHash,
        uint256 totalAmount,
        uint256 totalYesAmount,
        uint256 totalNoAmount
    );

    /// @notice Creates a new prediction question
    /// @param _question The question string
    /// @param _creatorImageHash IPFS hash of the creator's image
    /// @param _description Detailed description of the event
    /// @param _resolverUrl URL for event resolution source
    /// @param _endTimestamp Time when the event ends
    function createQuestion(
        string memory _question,
        string memory _creatorImageHash,
        string memory _description,
        string memory _resolverUrl,
        uint256 _endTimestamp
    ) public {
        require(msg.sender == owner, "Unauthorized");

        uint256 timestamp = block.timestamp;

        Questions storage question = questions[totalQuestions];

        question.id = totalQuestions++;
        question.question = _question;
        question.timestamp = timestamp;
        question.createdBy = msg.sender;
        question.creatorImageHash = _creatorImageHash;
        question.totalAmount = 0;
        question.totalYesAmount = 0;
        question.totalNoAmount = 0;
        question.description = _description;
        question.resolverUrl = _resolverUrl;
        question.endTimestamp = _endTimestamp;

        emit QuestionCreated(
            totalQuestions,
            _question,
            timestamp,
            msg.sender,
            _creatorImageHash,
            0,
            0,
            0
        );
    }

    /// @notice Places a YES bet on a specific question
    /// @param _questionId The ID of the question to bet on
    /// @param _value The amount of PolyToken to bet
    function addYesBet(uint256 _questionId, uint256 _value) public payable {
        require(_questionId < totalQuestions, "Question does not exist");
        Questions storage question = questions[_questionId];
        bool success = ERC20(polyToken).transferFrom(msg.sender, address(this), _value);
        require(success, "Transfer failed");
        AmountAdded memory amountAdded = AmountAdded({
            user: msg.sender,
            amount: _value,
            timestamp: block.timestamp
        });

        question.totalYesAmount += _value;
        question.totalAmount += _value;
        question.yesCount.push(amountAdded);
    }

    /// @notice Places a NO bet on a specific question
    /// @param _questionId The ID of the question to bet on
    /// @param _value The amount of PolyToken to bet
    function addNoBet(uint256 _questionId, uint256 _value) public payable {
        require(_questionId < totalQuestions, "Question does not exist");
        Questions storage question = questions[_questionId];
        bool success = ERC20(polyToken).transferFrom(msg.sender, address(this), _value);
        require(success, "Transfer failed");
        AmountAdded memory amountAdded = AmountAdded({
            user: msg.sender,
            amount: _value,
            timestamp: block.timestamp
        });

        question.totalNoAmount += _value;
        question.totalAmount += _value;
        question.noCount.push(amountAdded);
    }

    /// @notice Retrieves betting data for a question (Yes and No bets)
    /// @param _questionId The ID of the question
    /// @return The arrays of Yes and No bets
    function getGraphData(uint256 _questionId)
        public
        view
        returns (AmountAdded[] memory, AmountAdded[] memory)
    {
        Questions storage question = questions[_questionId];
        return (question.yesCount, question.noCount);
    }

    /// @notice Distributes winnings to the winners based on the outcome
    /// @dev Only the owner can resolve the event
    /// @param _questionId The ID of the question to resolve
    /// @param eventOutcome True for YES, False for NO
    function distributeWinningAmount(uint256 _questionId, bool eventOutcome) public {
        require(msg.sender == owner, "Unauthorized");
        Questions storage question = questions[_questionId];
        require(!question.eventCompleted, "Event already completed");

        if (eventOutcome) {
            // YES Won
            require(question.totalYesAmount > 0, "No winners exists");
            for (uint256 i = 0; i < question.yesCount.length; i++) {
                address user = question.yesCount[i].user;
                uint256 betAmount = question.yesCount[i].amount;
                
                // Calculate their share
                uint256 winnings = (question.totalNoAmount * betAmount) / question.totalYesAmount;
                
                // Update their balance (Cheaper than transferring)
                claimableWinnings[user] += (betAmount + winnings);
            }
        } else {
            // NO Won
            require(question.totalNoAmount > 0, "No winners exists");
            for (uint256 i = 0; i < question.noCount.length; i++) {
                address user = question.noCount[i].user;
                uint256 betAmount = question.noCount[i].amount;
                
                uint256 winnings = (question.totalYesAmount * betAmount) / question.totalNoAmount;
                
                // Update their balance
                claimableWinnings[user] += (betAmount + winnings);
            }
        }
        question.eventCompleted = true;
    }

    function claimWinnings() public {
        uint256 amount = claimableWinnings[msg.sender];
        require(amount > 0, "No winnings to claim");

        // IMPORTANT: Reset balance to 0 BEFORE sending money (Security fix)
        claimableWinnings[msg.sender] = 0; 
        
        bool success = ERC20(polyToken).transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }

    /// @notice Checks if the caller is the owner
    /// @return bool True if caller is owner, false otherwise
    function isAdmin() public view returns (bool) {
        if (msg.sender == owner) return true;
        else return false;
    }

    /// @notice Gets the total amounts bet on a question
    /// @param _questionId The ID of the question
    /// @return totalAmount Total amount bet
    /// @return totalYesAmount Total amount on YES
    /// @return totalNoAmount Total amount on NO
    function getQuestionTotals(uint256 _questionId) public view returns (uint256, uint256, uint256) {
        Questions storage q = questions[_questionId];
        return (q.totalAmount, q.totalYesAmount, q.totalNoAmount);
    }
}