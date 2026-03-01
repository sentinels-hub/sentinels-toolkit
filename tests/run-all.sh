#!/usr/bin/env bash
# tests/run-all.sh — Run all tests and report results
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors (inline, not dependent on lib)
if [[ -t 1 ]]; then
  C_RED='\033[0;31m'
  C_GREEN='\033[0;32m'
  C_BOLD='\033[1m'
  C_DIM='\033[2m'
  C_RESET='\033[0m'
else
  C_RED='' C_GREEN='' C_BOLD='' C_DIM='' C_RESET=''
fi

echo -e "${C_BOLD}╔══════════════════════════════════════╗${C_RESET}"
echo -e "${C_BOLD}║   sentinels-toolkit test suite       ║${C_RESET}"
echo -e "${C_BOLD}╚══════════════════════════════════════╝${C_RESET}"
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0
SUITES=0
FAILED_SUITES=()

run_test() {
  local name="$1"
  local script="$2"
  SUITES=$((SUITES + 1))

  echo -e "${C_BOLD}▸ ${name}${C_RESET}"

  set +e
  output=$(bash "$script" 2>&1)
  exit_code=$?
  set -e

  echo "$output" | while IFS= read -r line; do
    echo "  $line"
  done

  if [[ $exit_code -eq 0 ]]; then
    echo -e "  ${C_GREEN}→ SUITE PASSED${C_RESET}"
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    echo -e "  ${C_RED}→ SUITE FAILED (exit $exit_code)${C_RESET}"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_SUITES+=("$name")
  fi
  echo ""

  # Export for subshell tracking
  echo "$TOTAL_PASS $TOTAL_FAIL" > "$SCRIPT_DIR/.test-results"
  if [[ ${#FAILED_SUITES[@]} -gt 0 ]]; then
    printf '%s\n' "${FAILED_SUITES[@]}" > "$SCRIPT_DIR/.test-failed"
  else
    rm -f "$SCRIPT_DIR/.test-failed"
  fi
}

# Clean up previous results
rm -f "$SCRIPT_DIR/.test-results" "$SCRIPT_DIR/.test-failed"

# Run test suites
run_test "Dispatcher" "$SCRIPT_DIR/test-dispatcher.sh"
run_test "Health" "$SCRIPT_DIR/test-health.sh"
run_test "Changelog" "$SCRIPT_DIR/test-changelog.sh"
run_test "Contract" "$SCRIPT_DIR/test-contract.sh"

# Summary
echo -e "${C_BOLD}════════════════════════════════════════${C_RESET}"

if [[ $TOTAL_FAIL -eq 0 ]]; then
  echo -e "${C_GREEN}${C_BOLD}ALL ${SUITES} SUITES PASSED ✓${C_RESET}"
  rm -f "$SCRIPT_DIR/.test-results" "$SCRIPT_DIR/.test-failed"
  exit 0
else
  echo -e "${C_RED}${C_BOLD}${TOTAL_FAIL} of ${SUITES} SUITES FAILED ✗${C_RESET}"
  if [[ -f "$SCRIPT_DIR/.test-failed" ]]; then
    echo -e "${C_RED}Failed:${C_RESET}"
    while IFS= read -r suite; do
      echo -e "  ${C_RED}• ${suite}${C_RESET}"
    done < "$SCRIPT_DIR/.test-failed"
  fi
  rm -f "$SCRIPT_DIR/.test-results" "$SCRIPT_DIR/.test-failed"
  exit 1
fi
