#!/usr/bin/env bash
# tests/test-health.sh — Tests for health command (with mocks)
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

echo "=== Health Tests ==="

# Create mock gh that returns fixture data
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

cat > "$MOCK_DIR/gh" <<'MOCK_GH'
#!/usr/bin/env bash
case "$*" in
  *"repo list"*)
    echo '[{"name":"test-repo","pushedAt":"2026-03-01T10:00:00Z","description":"Test repo"}]'
    ;;
  *"pr list"*)
    echo '[{"number":1},{"number":2}]'
    ;;
  *"repo view"*)
    echo "main"
    ;;
  *"check-runs"*)
    echo '{"check_runs":[{"conclusion":"success"}]}'
    ;;
  *"contents/.sentinels/contract.json"*)
    # Return base64-encoded contract
    echo '{"content":"eyJzdGF0dXMiOiJhY3RpdmUifQ=="}'
    ;;
  *)
    echo "[]"
    ;;
esac
MOCK_GH
chmod +x "$MOCK_DIR/gh"

# Also need jq and curl to be available (real ones)
export PATH="$MOCK_DIR:$PATH"

# Test --help
assert_exit_code "health --help exits 0" 0 "$TOOLKIT" health --help
assert_output_contains "health --help shows usage" "Usage" "$TOOLKIT" health --help

# Test with mock data
assert_output_contains "health shows dashboard title" "Health Dashboard" "$TOOLKIT" health
assert_output_contains "health shows REPOSITORY header" "REPOSITORY" "$TOOLKIT" health
assert_output_contains "health shows repo name" "test-repo" "$TOOLKIT" health
assert_output_contains "health shows PRs header" "PRs" "$TOOLKIT" health

echo ""
echo "Health: $PASS passed, $FAIL failed"
exit "$FAIL"
