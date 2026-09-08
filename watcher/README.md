# Dry PONS watcher

Read-only `PoolGraduated` log scanner. **No private keys. No broadcast.**

Canonical script: [`../scripts/pons_watcher.py`](../scripts/pons_watcher.py)

```bash
cd /workspace/rh-build/hood-arena
python3 scripts/pons_watcher.py
python3 scripts/pons_watcher.py --blocks 5000 --dry-resolve
```

See root README § Dry PONS watcher.

Note: RH RPC may 403 without a browser-like User-Agent; the script sets one.
