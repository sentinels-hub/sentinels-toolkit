#!/usr/bin/env bash
# commands/contract.sh — Contract viewer (read-only)

cmd_contract() {
  local contract_path=""

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        cat <<EOF
Usage: sentinels-toolkit contract [path]

View contract status from .sentinels/contract.json.

Arguments:
  path    Path to project root (default: .)

The contract file is read-only — this command never modifies it.
EOF
        return 0
        ;;
      -*)
        echo -e "${RED:-}Unknown option: $1${RESET:-}" >&2
        return 1
        ;;
      *)
        contract_path="$1"
        shift
        ;;
    esac
  done

  # Default path
  if [[ -z "$contract_path" ]]; then
    contract_path="."
  fi

  # Find contract file
  local contract_file="${contract_path}/.sentinels/contract.json"
  if [[ ! -f "$contract_file" ]]; then
    echo -e "${RED:-}ERROR:${RESET:-} Contract file not found: ${contract_file}" >&2
    echo "Make sure you're in a project with .sentinels/contract.json" >&2
    return 1
  fi

  require_deps jq || return 1

  # Read contract
  local contract
  contract=$(cat "$contract_file")

  # Extract fields
  local contract_id status actor work_package created_at updated_at
  contract_id=$(echo "$contract" | jq -r '.contract_id // "unknown"')
  status=$(echo "$contract" | jq -r '.status // "unknown"')
  actor=$(echo "$contract" | jq -r '.actor // "unknown"')
  work_package=$(echo "$contract" | jq -r '.work_package // "—"')
  created_at=$(echo "$contract" | jq -r '.created_at // "—"')
  updated_at=$(echo "$contract" | jq -r '.updated_at // "—"')

  # Status color
  local status_display
  case "$status" in
    active)   status_display="${GREEN:-}● active${RESET:-}" ;;
    closed)   status_display="${DIM:-}○ closed${RESET:-}" ;;
    failed)   status_display="${RED:-}✗ failed${RESET:-}" ;;
    *)        status_display="${YELLOW:-}? ${status}${RESET:-}" ;;
  esac

  # Print box
  local box_width=60
  echo ""
  print_box_header "CONTRACT" "$box_width"
  print_box_line "" "$box_width"
  print_box_line "${BOLD:-}ID:${RESET:-}       ${contract_id}" "$box_width"
  print_box_line "${BOLD:-}Status:${RESET:-}   ${status_display}" "$box_width"
  print_box_line "${BOLD:-}Actor:${RESET:-}    ${actor}" "$box_width"
  print_box_line "${BOLD:-}WP:${RESET:-}       #${work_package}" "$box_width"
  print_box_line "" "$box_width"

  # Timeline
  print_box_line "${DIM:-}Created:  ${created_at}${RESET:-}" "$box_width"
  print_box_line "${DIM:-}Updated:  ${updated_at}${RESET:-}" "$box_width"
  print_box_line "" "$box_width"

  # Gates
  print_box_line "${BOLD:-}GATES${RESET:-}" "$box_width"
  print_box_line "" "$box_width"

  local gates
  gates=$(echo "$contract" | jq -r '.gates // {}')

  if [[ "$gates" != "{}" && "$gates" != "null" ]]; then
    local gate_keys
    gate_keys=$(echo "$gates" | jq -r 'keys[]' | sort)

    while IFS= read -r gate; do
      local gate_status gate_icon gate_color
      gate_status=$(echo "$gates" | jq -r ".\"$gate\"" 2>/dev/null)

      # Handle both string values and object values
      if echo "$gate_status" | jq -e '.status' &>/dev/null 2>&1; then
        gate_status=$(echo "$gate_status" | jq -r '.status')
      fi

      case "$gate_status" in
        passed)
          gate_icon="🟢"
          gate_color="${GREEN:-}"
          ;;
        failed)
          gate_icon="🔴"
          gate_color="${RED:-}"
          ;;
        skipped)
          gate_icon="🟡"
          gate_color="${YELLOW:-}"
          ;;
        pending|*)
          gate_icon="⚪"
          gate_color="${DIM:-}"
          ;;
      esac

      print_box_line "  ${gate_icon} ${gate_color}${gate}${RESET:-}  ${gate_color}${gate_status}${RESET:-}" "$box_width"
    done <<< "$gate_keys"
  else
    print_box_line "${DIM:-}  No gates defined${RESET:-}" "$box_width"
  fi

  print_box_line "" "$box_width"

  # Links
  local evidence_url github_pr github_commit
  evidence_url=$(echo "$contract" | jq -r '.evidence_url // empty')
  github_pr=$(echo "$contract" | jq -r '.github_pr // empty')
  github_commit=$(echo "$contract" | jq -r '.github_commit // empty')

  if [[ -n "$evidence_url" || -n "$github_pr" || -n "$github_commit" ]]; then
    print_box_line "${BOLD:-}LINKS${RESET:-}" "$box_width"
    [[ -n "$evidence_url" ]] && print_box_line "  Evidence: ${UNDERLINE:-}${evidence_url}${RESET:-}" "$box_width"
    [[ -n "$github_pr" ]] && print_box_line "  PR:       ${UNDERLINE:-}${github_pr}${RESET:-}" "$box_width"
    [[ -n "$github_commit" ]] && print_box_line "  Commit:   ${UNDERLINE:-}${github_commit}${RESET:-}" "$box_width"
    print_box_line "" "$box_width"
  fi

  print_box_footer "$box_width"
  echo ""
}
