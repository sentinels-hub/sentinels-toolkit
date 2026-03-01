#!/usr/bin/env bash
# tests/test-dispatcher.sh — Tests for the main dispatcher
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT="$SCRIPT_DIR/../bin/sentinels-toolkit"
PASS=0
FAIL=0

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

echo "=== Dispatcher Tests ==="

# --help
assert_exit_code "--help exits 0" 0 "$TOOLKIT" --help
assert_output_contains "--help shows usage" "USAGE" "$TOOLKIT" --help
assert_output_contains "--help shows commands" "COMMANDS" "$TOOLKIT" --help
assert_output_contains "--help lists health" "health" "$TOOLKIT" --help
assert_output_contains "--help lists changelog" "changelog" "$TOOLKIT" --help
assert_output_contains "--help lists contract" "contract" "$TOOLKIT" --help

# --version
assert_exit_code "--version exits 0" 0 "$TOOLKIT" --version
assert_output_contains "--version shows version" "sentinels-toolkit v" "$TOOLKIT" --version

# No args
assert_exit_code "no args exits 1" 1 "$TOOLKIT"
assert_output_contains "no args shows help" "USAGE" "$TOOLKIT"

# Unknown command
assert_exit_code "unknown command exits 1" 1 "$TOOLKIT" foobar
assert_output_contains "unknown command shows error" "Unknown command" "$TOOLKIT" foobar

# help alias
assert_exit_code "help alias exits 0" 0 "$TOOLKIT" help
assert_output_contains "help alias shows usage" "USAGE" "$TOOLKIT" help

# version alias
assert_exit_code "version alias exits 0" 0 "$TOOLKIT" version
assert_output_contains "version alias shows version" "sentinels-toolkit v" "$TOOLKIT" version

echo ""
echo "Dispatcher: $PASS passed, $FAIL failed"
exit "$FAIL"
