// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title Migrations
/// @notice Contract to keep track of which migrations have been done
contract Migrations {
  address public owner = msg.sender;
  uint public lastCompletedMigration;

  /// @notice Restricts access to the owner
  modifier restricted() {
    _restricted();
    _;
  }

  /// @dev Internal function to check if sender is owner
  function _restricted() internal view {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
  }

  /// @notice Updates the last completed migration
  /// @param completed The migration number that was completed
  function setCompleted(uint completed) public restricted {
    lastCompletedMigration = completed;
  }
}