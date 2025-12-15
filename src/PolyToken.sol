// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title PolyToken
/// @notice A simple ERC20 token for the Polymarket clone with a fixed initial supply and owner-only minting.
contract PolyToken is ERC20 {
    address public owner;

    /// @notice Initializes the token with name "Poly Token" and symbol "POLY".
    /// @dev Mints 100,000 tokens to the deployer.
    constructor() ERC20("Poly Token", "POLY") {
        owner = msg.sender;
        _mint(msg.sender, 100000 * 10**18);
    }

    /// @notice Mints new tokens to a specified address.
    /// @dev Only the owner can call this function.
    /// @param to The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner can mint");
        _mint(to, amount);
    }
}