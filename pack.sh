#!/usr/bin/env bash
# Build claude-usage.plasmoid (a zip with metadata.json at root) for KDE Store upload.
# Uses python stdlib so no `zip` package is needed.
set -euo pipefail
cd "$(dirname "$0")"
ver=$(python3 -c "import json;print(json.load(open('metadata.json'))['KPlugin']['Version'])")
out="claude-usage-${ver}.plasmoid"
rm -f "$out"
python3 - "$out" <<'PY'
import sys, zipfile, pathlib
out = sys.argv[1]
root = pathlib.Path(".")
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.write("metadata.json")
    for p in sorted(root.glob("contents/**/*")):
        if p.is_file():
            z.write(p)
print("built", out)
PY
