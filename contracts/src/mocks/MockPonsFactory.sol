// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPonsV2LaunchFactory} from "../interfaces/IPonsV2LaunchFactory.sol";

/// @notice Test mock of PONS V2 LaunchFactory getLaunchedToken view.
contract MockPonsFactory is IPonsV2LaunchFactory {
    mapping(address => LaunchedToken) internal _launched;

    function setExists(address token, bool exists_) external {
        LaunchedToken storage lt = _launched[token];
        lt.token = token;
        lt.exists = exists_;
    }

    function setPhase(address token, Phase phase_) external {
        LaunchedToken storage lt = _launched[token];
        lt.token = token;
        lt.exists = true;
        lt.phase = phase_;
    }

    function setSweptAt(address token, uint256 sweptAt_) external {
        LaunchedToken storage lt = _launched[token];
        lt.token = token;
        lt.exists = true;
        lt.sweptAt = sweptAt_;
    }

    /// @notice Convenience: exists + phase + sweptAt in one call
    function setLaunch(address token, Phase phase_, uint256 sweptAt_, bool exists_) external {
        _launched[token] = LaunchedToken({
            token: token,
            curve: address(0),
            deployer: address(0),
            creatorFeeRecipient: address(0),
            pairToken: address(0),
            graduationThreshold: 0,
            poolFee: 0,
            tickSpacing: 0,
            creatorTaxBps: 0,
            buybackEnabled: false,
            phase: phase_,
            sweptQuote: 0,
            sweptTokens: 0,
            sweptAt: sweptAt_,
            exists: exists_
        });
    }

    function getLaunchedToken(address token) external view returns (LaunchedToken memory) {
        return _launched[token];
    }
}
