#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURE="$SCRIPT_DIR/fixture"

# Clean generated state so stale output cannot satisfy assertions
rm -rf "$FIXTURE/overlay" "$FIXTURE/.lifecycle"

# Rebuild and start the nested fixture from a clean container
devcontainer up \
  --workspace-folder "$FIXTURE" \
  --mount-workspace-git-root false \
  --remove-existing-container

# 1. Command resolves from PATH with expected help marker
help_out=$(devcontainer exec --workspace-folder "$FIXTURE" -- local-feature-command --help)
echo "command help: $help_out"
echo "$help_out" | grep -q "Installed by devcontainer feature" \
  || { echo "FAIL: help marker absent"; exit 1; }

# 2. Materialized overlay matches documentation-feature source
overlay="$FIXTURE/overlay/NOTES.md"
source_doc="$FIXTURE/.devcontainer/features/documentation/NOTES.md"
[ -f "$overlay" ] || { echo "FAIL: overlay/NOTES.md not materialized"; exit 1; }
diff "$overlay" "$source_doc" || { echo "FAIL: overlay content does not match source"; exit 1; }
echo "overlay: $overlay matches source"

# 3. Overlay destination is gitignored
git -C "$FIXTURE" check-ignore overlay/NOTES.md \
  || { echo "FAIL: overlay/NOTES.md is not gitignored"; exit 1; }
echo "gitignore: overlay/NOTES.md is ignored"

# 4. Lifecycle evidence contains the expected hook marker
evidence="$FIXTURE/.lifecycle/executed"
[ -f "$evidence" ] || { echo "FAIL: lifecycle evidence file missing"; exit 1; }
grep -q "00-hello.sh" "$evidence" \
  || { echo "FAIL: 00-hello.sh marker absent in lifecycle evidence"; exit 1; }
echo "lifecycle evidence: $(cat "$evidence")"

# 5. No implementation files outside feature subdirectories
found=$(find "$FIXTURE" \
  -not -path "$FIXTURE/.devcontainer/features/*" \
  \( -name "local-feature-command" -o -name "lifecycle-runner" -o -name "00-hello.sh" \) \
  2>/dev/null || true)
[ -z "$found" ] || { echo "FAIL: implementation files outside features: $found"; exit 1; }
echo "isolation: no implementation copies outside features"

echo ""
echo "PASS"
