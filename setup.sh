#!/usr/bin/env bash
# setup.sh — verify the dev environment and run the GdUnit4 test suite.
#
# SNAPSHOT NOTE: the GdUnit4 addon lives under godot-project/addons/, which is
# .gitignored (third-party plugin, treated as a local dev dependency). A fresh
# `git clone` will therefore NOT contain the test runner. To create the
# identical base snapshot used for both model runs, COPY THE WORKING TREE
# (e.g. `cp -R Nice Nice-modelA`) rather than re-cloning, so that
# addons/gdUnit4/ comes along.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/godot-project"
RUNNER="addons/gdUnit4/bin/GdUnitCmdTool.gd"

echo "==> Checking Godot..."
if ! command -v godot >/dev/null 2>&1; then
  echo "ERROR: 'godot' not found on PATH. Install Godot 4.3+ (https://godotengine.org/download)." >&2
  exit 1
fi
godot --version

echo "==> Checking Python (used by the tools/ data pipeline)..."
if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "WARN: python3 not found; the tools/ data pipeline scripts will not run." >&2
fi

echo "==> Checking GdUnit4 addon..."
if [ ! -f "$PROJECT_DIR/$RUNNER" ]; then
  echo "ERROR: GdUnit4 runner not found at godot-project/$RUNNER" >&2
  echo "       The addon is gitignored. Restore it by copying the snapshot's" >&2
  echo "       godot-project/addons/gdUnit4/ directory, or install GdUnit4 (4.x)" >&2
  echo "       via the Godot editor's AssetLib." >&2
  exit 1
fi
ADDON_VERSION="$(grep -E '^version=' "$PROJECT_DIR/addons/gdUnit4/plugin.cfg" 2>/dev/null | head -1 | cut -d'"' -f2 || true)"
echo "    GdUnit4 version: ${ADDON_VERSION:-unknown}"

echo "==> Running test suite (headless)..."
cd "$PROJECT_DIR"
set +e
godot --headless -s "$RUNNER" -a tests -c --ignoreHeadlessMode
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  echo "==> All tests passed."
else
  echo "==> Tests FAILED (exit $STATUS)." >&2
fi
exit $STATUS
