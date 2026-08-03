#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p build/web
godot --headless --path . --export-release "Web" build/web/index.html
(cd build && zip -qr web.zip web)
echo "OK build/web + build/web.zip"
echo "Serve: python3 scripts/tools/serve_web.py 8770"
