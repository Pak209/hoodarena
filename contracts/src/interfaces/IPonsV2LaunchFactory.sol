// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice PONS V2 LaunchFactory surface for on-chain-verifiable graduation.
/// @dev From ponsdotdev/ponsfamily ILaunchFactory + docs.ponsfamily.com/v2.
///      `phase` is authoritative — do not infer graduation from events.
///      PoolGraduated(token, poolId, pool) is optional audit trail only.
interface IPonsV2LaunchFactory {
    enum Phase {
        NotGraduated, // 0 — trading on curve
        Swept, // 1 — curve drained; pool not yet created (transient)
        PoolCreated, // 2 — Uniswap v4 pool live ≈ graduated (YES unlock)
        Rescued // 3 — recovery
    }

    struct LaunchedToken {
        address token;
        address curve;
        address deployer;
        address creatorFeeRecipient;
        address pairToken;
        uint256 graduationThreshold;
        uint24 poolFee;
        int24 tickSpacing;
        uint16 creatorTaxBps;
        bool buybackEnabled;
        Phase phase;
        uint256 sweptQuote;
        uint256 sweptTokens;
        uint256 sweptAt;
        bool exists;
    }

    function getLaunchedToken(address token) external view returns (LaunchedToken memory);
}
