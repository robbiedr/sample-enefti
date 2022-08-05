// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC20WithPermit.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {EIP712Base} from "./base/EIP712Base.sol";

contract ERC7212WithPermit is ERC721, EIP712Base, AccessControl {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  bytes32 private constant MINT_PERMIT_TYPEHASH = 
    keccak256("MintPermit(address purchaser,address seller,uint256 deadline)");
  bytes32 private constant TRANSFER_PERMIT_TYPEHASH = 
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  // Mapping from token id to token uri
  mapping(uint256 => string) private _tokenUris;

  /**
   * @dev Emitted when `buyer` purchase a single block in an artwork
   */
  event PurchaseBlock(address indexed seller, address indexed buyer, uint256 indexed tokenId, string tokenUri);
  
  /**
   * @dev Emitted when `buyer` purchase a multiple blocks in an artwork
   */
  event PurchaseBlocks(address indexed seller, address indexed buyer, uint256[] indexed tokenIds, string[] tokenUris);

  /**
   * @dev Constructor
   */
  constructor(
      string memory _name_,
      string memory _symbol_
    ) ERC721(_name_, _symbol_) EIP712Base() {
      _grantRole(MINTER_ROLE, msg.sender);
      _grantRole(OWNER_ROLE, msg.sender);
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

      _domainSeparator = _calculateDomainSeparator();
    }

  function mintSigleBlockWithPermit(
    address to,
    string memory tokenUri,
    uint256 value,
    address seller,
    uint256 deadline,
    bytes memory mintSignature,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    verifyMintSig(
      to,
      seller,
      deadline,
      mintSignature
    );

    verifyTransferPermit(
      to,
      value,
      deadline,
      v,
      r,
      s
    );

    IERC20WithPermit(0x21C561e551638401b937b03fE5a0a0652B99B7DD).transferFrom(to, seller, value);

    uint256 tokenId = _tokenIdCounter.current();

    _mint(to, tokenId);
    _setTokenUri(tokenId, tokenUri);

    _tokenIdCounter.increment();

    emit PurchaseBlock(address(0), to, tokenId, tokenUri);
  }

  function mintBatchBlocksWithPermit(
    address to,
    address seller,
    uint256 quantity,
    string[] memory tokenUris,
    uint256 value,
    uint256 deadline,
    bytes memory mintSignature,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(quantity == tokenUris.length, "INVALID_TOKEN_QUANTITY");
    verifyMintSig(
      to,
      seller,
      deadline,
      mintSignature
    );

    verifyTransferPermit(
      to,
      value,
      deadline,
      v,
      r,
      s
    );

    IERC20WithPermit(0x21C561e551638401b937b03fE5a0a0652B99B7DD).transferFrom(to, seller, value);

    uint256[] memory tokenIds = new uint256[](quantity);

    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = _tokenIdCounter.current();

      _mint(to, tokenId);
      _setTokenUri(tokenId, tokenUris[i]);

      _tokenIdCounter.increment();
    }

    emit PurchaseBlocks(address(0), to, tokenIds, tokenUris);
  }

  /// @inheritdoc ERC721
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    return _tokenUris[tokenId];
  }

  function _setTokenUri(uint256 tokenId, string memory tokenUri) internal {
    _tokenUris[tokenId] = tokenUri;
  }

  function verifyMintSig(
    address purchaser,
    address seller,
    uint256 deadline,
    bytes memory signature
  ) internal view {
    require(block.timestamp <= deadline, "Artifract: INVALID_DEADLINE");
    address signer = recoverAddress(
      DOMAIN_SEPARATOR(),
      keccak256(abi.encode(MINT_PERMIT_TYPEHASH, purchaser, seller, deadline)),
      signature
    );

    require(hasRole(MINTER_ROLE, signer), "Artifract: INVALID_SIGNATURE");
  }

  function verifyTransferPermit(
    address owner,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    IERC20WithPermit(0x21C561e551638401b937b03fE5a0a0652B99B7DD).permit(
      owner,
      address(this),
      value,
      deadline,
      v,
      r,
      s
    );
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /// @inheritdoc EIP712Base
  function _eip712BaseId() internal view override returns (string memory) {
      return name();
  }
}