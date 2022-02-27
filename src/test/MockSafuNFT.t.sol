// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {MockSafuNFT} from "./MockSafuNFT.sol";

/*
    Someone who didn't lock can transfer
    Someone who locked cannot transfer
    Someone who didn't lock cannot get a refund
    Someone who locked can get a refund
    Someone who locked cannot get a refund after the lock period ends
    Someone who locked cannot redeem before lock ends
*/
contract MockSafuNFTTest is DSTestPlus {
    MockSafuNFT safu;

    uint256 maxSupply = 5;
    uint256 price = 1 ether;
    uint256 lockEnd = block.timestamp + 30 days;
    string name = "SafuNFT";
    string symbol = "SNFT";

    function setUp() public {
        safu = new MockSafuNFT(maxSupply, price, lockEnd, name, symbol);
        vm.warp(0);
    }

    function test_NotLockedCanTransfer() public {
        safu.buy{value: price}(false);
        safu.transferFrom(address(this), address(0xBEEF), 0);
        assertEq(safu.balanceOf(address(this)), 0);
    }

    function test_LockedCannotTransfer() public {
        safu.buy{value: price}(true);
        vm.expectRevert("WRONG_FROM"); // locked == not owning it yet
        safu.transferFrom(address(this), address(0xBEEF), 0);
    }

    function test_NoLockNoRefund() public {
        safu.buy{value: price}(false);
        vm.expectRevert("NOT_LOCKED");
        safu.refund(0);
    }

    function test_LockedCanRefund() public {
        safu.buy{value: price}(true);
        safu.refund(0);
        assertEq(address(safu).balance, 0);
        assertEq(safu.vouchers(0), address(0));
    }

    function test_CannotRefundIfTooLate() public {
        safu.buy{value: price}(true);
        vm.warp(lockEnd + 1 days);
        vm.expectRevert("LOCK_PERIOD_OVER");
        safu.refund(0);
    }

    function test_CannotRedeemBeforeLockEnds() public {
        safu.buy{value: price}(true);
        vm.expectRevert("LOCKED");
        safu.redeem(0);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0x150b7a02;
    }

    receive() external payable {}
}
