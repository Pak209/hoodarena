#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "contracts" / "out"
DEST = ROOT / "web" / "src" / "abi"
CONTRACTS = {
    "Arena": OUT / "Arena.sol" / "Arena.json",
    "GraduationRace": OUT / "GraduationRace.sol" / "GraduationRace.json",
    "PlayerCard": OUT / "PlayerCard.sol" / "PlayerCard.json",
    "CardPack": OUT / "CardPack.sol" / "CardPack.json",
}
def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for name, path in CONTRACTS.items():
        if not path.exists():
            raise SystemExit(f"missing artifact {path}; run forge build first")
        art = json.loads(path.read_text())
        abi = art["abi"]
        dest = DEST / f"{name}.json"
        dest.write_text(json.dumps(abi, indent=2) + "\n")
        print(f"wrote {dest} ({len(abi)} entries)")
if __name__ == "__main__":
    main()
