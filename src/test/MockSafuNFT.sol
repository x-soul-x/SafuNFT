// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {SafuNFT} from "../SafuNFT.sol";

contract MockSafuNFT is SafuNFT {
    uint256 public MAX_SUPPLY;
    uint256 public PRICE;
    uint256 public totalSupply;

    constructor(
        uint256 maxSupply_,
        uint256 price_,
        uint256 lockEnd_,
        string memory name_,
        string memory symbol_
    ) SafuNFT(lockEnd_, name_, symbol_) {
        MAX_SUPPLY = maxSupply_;
        PRICE = price_;
    }

    function buy(bool shouldLock) public payable {
        require(msg.value == PRICE, "MSG.VALUE");
        uint256 tokenId = totalSupply++;
        require(totalSupply <= MAX_SUPPLY, "OVER_MAX_SUPPLY");
        if (shouldLock) {
            _lock(msg.sender, tokenId);
        } else {
            _safeMint(msg.sender, tokenId);
        }
    }

    function refund(uint256 tokenId) public {
        _refund(msg.sender, tokenId, PRICE);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}
