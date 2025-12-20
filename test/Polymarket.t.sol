// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {Test} from "forge-std/Test.sol";
import {Polymarket} from "../src/Polymarket.sol";
import {PolyToken} from "../src/PolyToken.sol";

contract PolymarketTest is Test {
    Polymarket public polymarket;
    PolyToken public polyToken;

    function setUp() public {
        // Deploy the token first
        polyToken = new PolyToken();
        // Deploy Polymarket with the token address
        polymarket = new Polymarket(address(polyToken));
    }

    function testCreateQuestion() public {
        string memory questionText = "Will ETH hit $10k in 2025?";
        string memory imageHash = "QmHashExample";
        string memory description = "Prediction market for ETH price.";
        string memory resolverUrl = "https://resolver.example.com";
        uint256 endTimestamp = block.timestamp + 365 days;

        // Call createQuestion
        polymarket.createQuestion(
            questionText,
            imageHash,
            description,
            resolverUrl,
            endTimestamp
        );

        uint256 totalQuestions = polymarket.totalQuestions();
        assertEq(totalQuestions, 1);
    }

    function _checkAmounts(uint256 total, uint256 yes, uint256 no) internal pure {
        assertEq(total, 0);
        assertEq(yes, 0);
        assertEq(no, 0);
    }

    function _checkDetails(bool completed, string memory desc, string memory url, string memory expectedDesc, string memory expectedUrl) internal pure {
        assertEq(completed, false);
        assertEq(desc, expectedDesc);
        assertEq(url, expectedUrl);
    }
    function testAddBet() public {
        // 1. Create Question
        polymarket.createQuestion(
            "Is Solang awesome?",
            "Hash123",
            "Description",
            "URL",
            block.timestamp + 1 days
        );

        // 2. Approve Polymarket to spend tokens
        uint256 betAmount = 100 * 10**18;
        polyToken.approve(address(polymarket), betAmount);

        // 3. Place Yes Bet
        polymarket.addYesBet(0, betAmount);

        // 4. Verify amounts
        (uint256 totalAmt, uint256 totalYes, uint256 totalNo) = polymarket.getQuestionTotals(0);

        assertEq(totalYes, betAmount, "Total Yes amount should match bet");
        assertEq(totalAmt, betAmount, "Total amount should match bet");
        assertEq(totalNo, 0, "Total No amount should be 0");
    }

    function testWinnings() public {
        uint256 betAmount = 100 * 10**18;
        address user2 = address(0x123);

        // 1. Setup Question
        polymarket.createQuestion("Q?", "H", "D", "U", block.timestamp + 100);

        // 2. Bet Yes (Test Contract)
        polyToken.approve(address(polymarket), betAmount);
        polymarket.addYesBet(0, betAmount);

        // 3. Bet No (User 2)
        // First mint tokens to user2
        polyToken.mint(user2, betAmount);
        
        // Impersonate user2
        vm.startPrank(user2);
        polyToken.approve(address(polymarket), betAmount);
        polymarket.addNoBet(0, betAmount);
        vm.stopPrank();

        // Check totals before distribution
        (uint256 total, uint256 yes, uint256 no) = polymarket.getQuestionTotals(0);
        assertEq(total, betAmount * 2, "Total should be 200");
        assertEq(yes, betAmount, "Yes should be 100");
        assertEq(no, betAmount, "No should be 100");

        // 4. Distribute Winnings (Outcome: YES)
        // Note: No automatic transfer happening here anymore
        polymarket.distributeWinningAmount(0, true);

        // 5. Verify Claimable Amount
        // Expected: Original 100 + 100 (won from loser) = 200 increase
        uint256 expectedWinnings = betAmount * 2;
        uint256 claimable = polymarket.claimableWinnings(address(this));
        assertEq(claimable, expectedWinnings, "Should have claimable winnings recorded");

        // 6. Claim Winnings
        uint256 balanceBefore = polyToken.balanceOf(address(this));
        polymarket.claimWinnings();
        uint256 balanceAfter = polyToken.balanceOf(address(this));
        
        assertEq(balanceAfter - balanceBefore, expectedWinnings, "Should receive tokens after claiming");
    }

    function testBettingOnSecondQuestion() public {
        // Create first question (ID 0)
        polymarket.createQuestion("Q1", "H1", "D1", "U1", block.timestamp + 100);
        // Create second question (ID 1)
        polymarket.createQuestion("Q2", "H2", "D2", "U2", block.timestamp + 100);

        uint256 betAmount = 10 * 10**18;
        polyToken.approve(address(polymarket), betAmount);

        // Try betting on ID 1 (should work now)
        polymarket.addYesBet(1, betAmount);
        
        (uint256 total, , ) = polymarket.getQuestionTotals(1);
        assertEq(total, betAmount, "Should be able to bet on question 1");
    }
}
