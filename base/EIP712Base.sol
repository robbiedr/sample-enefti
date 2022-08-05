// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity 0.8.9;

/// @title EIP712Base
/// @notice Base contract implementation of EIP712
abstract contract EIP712Base {
  using ECDSA for bytes32;

  // Map from address to nonces
  mapping(address => uint256) internal _nonces;

  bytes32 internal _domainSeparator;
  uint256 internal immutable _chainId;

  /**
   * @dev Constructor
   */
  constructor() {
    _chainId = block.chainid;
  }

  /// @notice Retrieve the domain separator for the token
  /// @return The domain separator for the token at current chain
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      (block.chainid == _chainId)
        ? _domainSeparator
        : _calculateDomainSeparator();
  }

  /// @notice Returns the nonce value for address specified as parameter
  /// @param owner The address for which the nonce is being returned
  /// @return The nonce value for the input `address`
  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner];
  }

  /// @notice Compute the current domain separator
  /// @return The domain separator for the token
  function _calculateDomainSeparator() internal view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
          keccak256(bytes(_eip712BaseId())),
          keccak256(bytes("1")),
          block.chainid,
          address(this)
        )
      );
  }

  function recoverAddress(bytes32 domainSeparator, bytes32 structHash, bytes memory signature) internal pure returns (address) {
    return ECDSA.toTypedDataHash(domainSeparator, structHash).recover(signature);
  }

  /// @notice Returns the user readable name of signing domain, i.e the name of the DApp or the protocol
  /// @return The name of the signing domain
  function _eip712BaseId() internal view virtual returns (string memory);
}