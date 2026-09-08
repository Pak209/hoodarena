#!/usr/bin/env python3
"""
Hood Arena — dry PONS PoolGraduated watcher (READ-ONLY).

LIVE LOCKED: never broadcasts, never uses private keys.
Uses eth_getLogs over a small recent block window on RH RPC.

Usage:
  python3 scripts/pons_watcher.py
  python3 scripts/pons_watcher.py --blocks 5000
  python3 scripts/pons_watcher.py --dry-resolve
  python3 scripts/pons_watcher.py --token 0x...
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from typing import Any

RPC_URL = "https://rpc.mainnet.chain.robinhood.com"
PONS_FACTORY = "0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e"
# PoolGraduated(token, positionId, tokenAmount, pairTokenAmount) — Field research
POOL_GRADUATED_TOPIC0 = (
    "0x0a44ef75df69c534f43cd6c1aa3ef8983065fe5fe79ef9e79f6494e6f258c259"
)
DEFAULT_BLOCKS = 8_000  # small recent window; bump with --blocks if needed
CHAIN_ID = 4663


def rpc(method: str, params: list[Any]) -> Any:
    body = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    ).encode()
    req = urllib.request.Request(
        RPC_URL,
        data=body,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 HoodArenaDryWatcher/0.1",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            payload = json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        raise SystemExit(f"RPC HTTP error {e.code}: {e.read()[:400]!r}") from e
    except urllib.error.URLError as e:
        raise SystemExit(f"RPC unreachable: {e}") from e
    if "error" in payload:
        raise SystemExit(f"RPC error: {payload['error']}")
    return payload["result"]


def hex_int(x: str) -> int:
    return int(x, 16)


def topic_address(topic: str) -> str:
    """Decode indexed address from 32-byte topic."""
    h = topic.lower().removeprefix("0x")
    return "0x" + h[-40:]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Read-only PONS PoolGraduated watcher (no keys, no broadcast)"
    )
    parser.add_argument(
        "--blocks",
        type=int,
        default=DEFAULT_BLOCKS,
        help=f"Lookback window in blocks (default {DEFAULT_BLOCKS})",
    )
    parser.add_argument(
        "--dry-resolve",
        action="store_true",
        help="Print keeper calls that WOULD be made (never broadcast)",
    )
    parser.add_argument(
        "--token",
        type=str,
        default=None,
        help="Optional token address filter (topic1)",
    )
    parser.add_argument(
        "--arena-id",
        type=int,
        default=None,
        help="Optional arenaId for --dry-resolve example prints",
    )
    parser.add_argument(
        "--race-id",
        type=int,
        default=None,
        help="Optional raceId for --dry-resolve example prints",
    )
    args = parser.parse_args()

    print("=== HOOD ARENA PONS WATCHER (DRY / READ-ONLY) ===")
    print(f"chainId:     {CHAIN_ID}")
    print(f"RPC:         {RPC_URL}")
    print(f"factory:     {PONS_FACTORY}")
    print(f"topic0:      {POOL_GRADUATED_TOPIC0}")
    print(f"event:       PoolGraduated")
    print("LIVE LOCKED — no broadcast, no private keys\n")

    latest = hex_int(rpc("eth_blockNumber", []))
    from_block = max(0, latest - max(1, args.blocks))
    print(f"block window: {from_block} → {latest} ({latest - from_block} blocks)\n")

    topics: list[Any] = [POOL_GRADUATED_TOPIC0]
    if args.token:
        t = args.token.lower().removeprefix("0x")
        if len(t) != 40:
            raise SystemExit("--token must be a 20-byte hex address")
        topics.append("0x" + ("0" * 24) + t)

    logs = rpc(
        "eth_getLogs",
        [
            {
                "fromBlock": hex(from_block),
                "toBlock": hex(latest),
                "address": PONS_FACTORY,
                "topics": topics,
            }
        ],
    )

    if not logs:
        print("No PoolGraduated logs in this window.")
        if args.dry_resolve:
            print("\n--dry-resolve: nothing to resolve from this window.")
            print(
                "  (If an arena deadline T passed with no event, keeper would call "
                "resolveArenaNo(arenaId) — not inferred here without arena state.)"
            )
        return 0

    print(f"Found {len(logs)} PoolGraduated event(s):\n")
    seen_tokens: list[str] = []
    for i, log in enumerate(logs, 1):
        topics_l = log.get("topics") or []
        token = topic_address(topics_l[1]) if len(topics_l) > 1 else "(unindexed?)"
        block = hex_int(log["blockNumber"])
        tx = log.get("transactionHash", "")
        print(f"  [{i}] block={block} token={token}")
        print(f"       tx={tx}")
        if token.startswith("0x") and token not in seen_tokens:
            seen_tokens.append(token)

    if args.dry_resolve:
        print("\n=== DRY RESOLVE (PRINT ONLY — NEVER BROADCAST) ===")
        print("Trust model: on-chain factory VIEW phase==2 (PoolCreated)")
        print("  YES: getLaunchedToken(token).phase == 2; late if sweptAt < deadline")
        print("  Events are NOT authoritative — confirm phase via eth_call before resolve")
        print("  Trusted-keeper unlock REJECTED by Pak")
        arena_id = args.arena_id if args.arena_id is not None else "<arenaId>"
        race_id = args.race_id if args.race_id is not None else "<raceId>"
        for token in seen_tokens:
            print(f"  IF arena.token == {token} AND phase==2 (confirm VIEW):")
            print(f"    → resolveArenaYes({arena_id})  # permissionless")
            print(f"  IF {token} earliest sweptAt among race[{race_id}] phase==2 AND winPot>0:")
            print(f"    → resolveRace({race_id}, {token})  # empty pot reverts")
        print(f"  IF T reached AND phase!=2 → resolveArenaNo({arena_id})  # permissionless")
        print(f"  IF race T reached AND none phase==2 → cancelRace({race_id})  # permissionless")
        print("  OPTIONAL: lockArena / lockRace (keeper) to close staking")
        print("\nNo transactions signed or sent. LIVE LOCKED.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
