// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

/// @title SafuNFT
/// @author soul <cinder.soul@protonmail.com>
abstract contract SafuNFT is ERC721 {
    /// >>>>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///
    event Locked(address indexed user, uint256 indexed tokenId);
    event Refunded(address indexed user, uint256 indexed tokenId);
    event Redeemed(uint256 indexed tokenId);

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    mapping(uint256 => address) public vouchers;
    uint256 public immutable LOCK_END;

    /// >>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<< ///

    constructor(
        uint256 lockEnd_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        LOCK_END = lockEnd_;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Redeem a locked tokenId
    /// @param tokenId tokenId to redeem
    function redeem(uint256 tokenId) public virtual {
        require(vouchers[tokenId] == msg.sender, "NOT_OWNED");
        require(block.timestamp >= LOCK_END, "LOCKED");
        delete vouchers[tokenId];
        emit Redeemed(tokenId);
        _safeMint(msg.sender, tokenId);
    }

    /// @notice Lock a tokenId for an user
    /// @param user address owning the token
    /// @param tokenId tokenId to redeem
    function _lock(address user, uint256 tokenId) internal virtual {
        require(vouchers[tokenId] == address(0), "ALREADY_LOCKED");
        vouchers[tokenId] = user;
        emit Locked(user, tokenId);
    }

    /// @notice Refund the eth to the user
    /// @param user address owning the token
    /// @param tokenId tokenId to be refunded
    /// @param value amount of eth to refund
    function _refund(
        address user,
        uint256 tokenId,
        uint256 value
    ) internal virtual {
        require(vouchers[tokenId] != address(0), "NOT_LOCKED");
        require(block.timestamp <= LOCK_END, "LOCK_PERIOD_OVER");
        delete vouchers[tokenId];
        SafeTransferLib.safeTransferETH(user, value);
        emit Refunded(user, tokenId);
    }

    /// @notice mint tokenId to an address
    /// @dev prevents minting a locked tokenId
    /// @param user address to mint to
    /// @param tokenId tokenId to be refunded
    function _mint(address user, uint256 tokenId) internal virtual override {
        require(vouchers[tokenId] == address(0), "ALREADY_LOCKED");
        super._mint(user, tokenId);
    }
}
