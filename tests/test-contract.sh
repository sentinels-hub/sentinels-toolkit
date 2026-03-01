#!/usr/bin/env bash
# tests/test-contract.sh — Tests for contract command (with fixtures)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT="$SCRIPT_DIR/../bin/sentinels-toolkit"
FIXTURES="$SCRIPT_DIR/fixtures"
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

echo "=== Contract Tests ==="

# Test --help
assert_exit_code "contract --help exits 0" 0 "$TOOLKIT" contract --help
assert_output_contains "contract --help shows usage" "Usage" "$TOOLKIT" contract --help

# Setup temp dir with active contract fixture
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
mkdir -p "$TEMP_DIR/.sentinels"

# Test active contract
cp "$FIXTURES/contract-active.json" "$TEMP_DIR/.sentinels/contract.json"

assert_exit_code "active contract exits 0" 0 "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows contract ID" "CTR-test-project-20260301" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows actor" "TestUser" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows WP number" "9999" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows CONTRACT header" "CONTRACT" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows GATES header" "GATES" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows G0" "G0" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows G3" "G3" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows passed status" "passed" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows pending status" "pending" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows green circle for passed" "🟢" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows white circle for pending" "⚪" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "shows evidence URL" "evidence" "$TOOLKIT" contract "$TEMP_DIR"

# Test closed contract
cp "$FIXTURES/contract-closed.json" "$TEMP_DIR/.sentinels/contract.json"

assert_exit_code "closed contract exits 0" 0 "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "closed shows contract ID" "CTR-completed-project" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "closed shows all passed" "passed" "$TOOLKIT" contract "$TEMP_DIR"
assert_output_contains "closed shows commit link" "Commit" "$TOOLKIT" contract "$TEMP_DIR"

# Test missing contract
assert_exit_code "missing contract exits 1" 1 "$TOOLKIT" contract /tmp

echo ""
echo "Contract: $PASS passed, $FAIL failed"
exit "$FAIL"
