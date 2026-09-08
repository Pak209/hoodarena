// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Stub PONS-style PoolGraduated emitter for forge tests
/// @notice Mimics the PONS V2 factory graduation signal used by Hood Arena resolve.
/// @dev Production resolve watches factory `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e`.
///      LIVE LOCKED — test stub only; do not deploy as a real factory.
contract GraduatedEmitter {
    /// @notice Same event name used as the Arena/Race resolve signal
    event PoolGraduated(address indexed token, address indexed pool, uint256 timestamp);

    /// @notice Emit a fake graduation for unit tests
    function emitGraduated(address token, address pool) external {
        emit PoolGraduated(token, pool, block.timestamp);
    }
}
