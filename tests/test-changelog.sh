#!/usr/bin/env bash
# tests/test-changelog.sh — Tests for changelog command (with mocks)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT="$SCRIPT_DIR/../bin/sentinels-toolkit"
PASS=0
FAIL=0

assert_output_contains() {
  local desc="$1" pattern="$2"
  shift 2
  local output
  set +e
  output=$("$@" 2>&1)
  set -e
  if echo "$output" | grep -q "$pattern"; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc (output missing: $pattern)"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2"
  shift 2
  local actual
  set +e
  "$@" &>/dev/null
  actual=$?
  set -e
  if [[ "$actual" -eq "$expected" ]]; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc (expected exit $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Changelog Tests ==="

# Test --help
assert_exit_code "changelog --help exits 0" 0 "$TOOLKIT" changelog --help
assert_output_contains "changelog --help shows usage" "Usage" "$TOOLKIT" changelog --help

# Create a temporary git repo with conventional commits
TEMP_REPO=$(mktemp -d)
trap 'rm -rf "$TEMP_REPO"' EXIT

git -C "$TEMP_REPO" init -q
git -C "$TEMP_REPO" config user.email "test@test.com"
git -C "$TEMP_REPO" config user.name "Test"

# Add commits
echo "initial" > "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add .
git -C "$TEMP_REPO" commit -q -m "feat(core): initial project setup"

echo "fix1" >> "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add .
git -C "$TEMP_REPO" commit -q -m "fix(api): handle null response"

echo "docs1" >> "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add .
git -C "$TEMP_REPO" commit -q -m "docs(readme): update installation guide"

echo "feat2" >> "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add .
git -C "$TEMP_REPO" commit -q -m "feat(auth): add JWT validation"

echo "test1" >> "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add .
git -C "$TEMP_REPO" commit -q -m "test(auth): add login tests"

echo "refactor1" >> "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add .
git -C "$TEMP_REPO" commit -q -m "refactor(core): extract validation logic"

# Test --stdout
local_output=$("$TOOLKIT" changelog --repo "$TEMP_REPO" --stdout 2>/dev/null)

check_contains() {
  local desc="$1" pattern="$2" text="$3"
  if echo "$text" | grep -q "$pattern"; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc (missing: $pattern)"
    FAIL=$((FAIL + 1))
  fi
}

check_contains "changelog has header" "# Changelog" "$local_output"
check_contains "changelog has Features section" "Features" "$local_output"
check_contains "changelog has Bug Fixes section" "Bug Fixes" "$local_output"
check_contains "changelog has Documentation section" "Documentation" "$local_output"
check_contains "changelog has Tests section" "Tests" "$local_output"
check_contains "changelog has Refactoring section" "Refactoring" "$local_output"
check_contains "changelog mentions JWT" "JWT" "$local_output"
check_contains "changelog mentions null response" "null response" "$local_output"

# Test --output writes file
"$TOOLKIT" changelog --repo "$TEMP_REPO" --output "$TEMP_REPO/CHANGELOG.md" 2>/dev/null
if [[ -f "$TEMP_REPO/CHANGELOG.md" ]]; then
  echo "  ✓ changelog writes output file"
  PASS=$((PASS + 1))
else
  echo "  ✗ changelog writes output file"
  FAIL=$((FAIL + 1))
fi

# Test non-git directory
assert_exit_code "non-git dir exits 1" 1 "$TOOLKIT" changelog --repo /tmp

echo ""
echo "Changelog: $PASS passed, $FAIL failed"
exit "$FAIL"
