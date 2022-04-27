// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__Cancel__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultCliffStream();
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.cancel(nonStreamId);
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotCancel__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When caller is the recipient, it should make the withdrawal.
    function testCancel__CallerRecipient() external {
        // Make the recipient the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.recipient);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the cliff stream is non-cancelable, it should revert.
    function testCannotCancel__StreamNonCancelable() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableStreamId)
        );
        sablierV2Cliff.cancel(nonCancelableStreamId);
    }

    /// @dev When the stream ended, it should cancel the stream.
    function testCancel__StreamEnded() external {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream ended, it should delete the cliff stream.
    function testCancel__StreamEnded__DeleteCliffStream() external {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.CliffStream memory expectedCliffStream;
        ISablierV2Cliff.CliffStream memory deletedCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(expectedCliffStream, deletedCliffStream);
    }

    /// @dev When the stream ended, it should emit a Cancel event.
    function testCancel__StreamEnded__Event() public {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = cliffStream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(streamId, cliffStream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should cancel the stream.
    function testCancel__StreamOngoing() external {
        // Warp to 36 seconds after the start time (1% of the default cliff stream duration).
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should delete the cliff stream.
    function testCancel__StreamOngoing__DeleteCliffStream() external {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.CliffStream memory expectedCliffStream;
        ISablierV2Cliff.CliffStream memory deletedCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(expectedCliffStream, deletedCliffStream);
    }

    /// @dev When the stream is ongoing, it should emit a Cancel event.
    function testCancel__StreamOngoing__Event() public {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = cliffStream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(streamId, cliffStream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancel(streamId);
    }
}