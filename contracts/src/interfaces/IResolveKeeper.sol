// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Resolve surface — on-chain PONS factory phase (permissionless)
/// @notice Graduation proof = `IPonsV2LaunchFactory.getLaunchedToken(token).phase == 2`
///         (PoolCreated). Not keeper-supplied timestamps. Trusted-keeper unlock REJECTED.
/// @dev LIVE LOCKED — no production deploy until Reviewer clear + Pak unlock.
interface IResolveKeeper {
    /// @notice YES when factory phase==2 (PoolCreated). Permissionless.
    ///         Time: now <= deadline OR (sweptAt != 0 && sweptAt < deadline).
    ///         Product: “swept before T and eventually PoolCreated” (no poolCreatedAt).
    function resolveArenaYes(uint256 arenaId) external;

    /// @notice NO after deadline. Before T+grace: only phase==0 or phase==3.
    ///         Swept (phase==1) reverts until grace. After grace: phase!=2 (incl. stuck Swept).
    function resolveArenaNo(uint256 arenaId) external;

    /// @notice Race winner when winner.phase==2 + earliest sweptAt among phase==2;
    ///         equal sweptAt → lowest token address. Same YES time rule.
    ///         If any sibling is Swept with sweptAt < T, wait until T+grace.
    ///         Empty win pot reverts. Permissionless.
    function resolveRace(uint256 raceId, address winnerToken) external;

    /// @notice Cancel race after deadline when none of three have phase==2.
    ///         If a Swept sibling (sweptAt < T) exists, wait until T+grace. Permissionless.
    function cancelRace(uint256 raceId) external;
}
