// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithPermit is IERC20 {
  /// @notice Allow passing a signed message from off-chain to approve spending of funds
  /// @dev Implements the permit function that complies with the with
  /// https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
  /// @param owner The owner of the funds
  /// @param spender The spender of the funds
  /// @param value The amount
  /// @param deadline The deadline timestamp
  /// @param v v
  /// @param r r 
  /// @param s s 
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}