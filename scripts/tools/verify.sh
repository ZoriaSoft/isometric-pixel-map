#!/usr/bin/env bash
# Local quality gate — version sync + selftest
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "FAIL: godot not in PATH"
  exit 1
fi

echo "== version sync =="
PROJ_VER=$(grep -E '^config/version=' project.godot | sed 's/.*"\(.*\)"/\1/')
APP_VER=$(grep -E 'APP_VERSION' scripts/autoload/Game.gd | head -1 | sed 's/.*"\(.*\)"/\1/')
echo "project.godot: $PROJ_VER"
echo "Game.APP_VERSION: $APP_VER"
if [[ "$PROJ_VER" != "$APP_VER" ]]; then
  echo "FAIL: project version != Game.APP_VERSION"
  exit 1
fi
echo "OK version sync"

echo "== script check =="
"$GODOT" --headless --path . --quit-after 1 2>&1 | tail -20

echo "== rules selftest =="
"$GODOT" --headless --path . -s res://scripts/tools/rules_selftest.gd

echo "VERIFY PASS"
