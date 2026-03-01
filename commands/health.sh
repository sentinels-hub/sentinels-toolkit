#!/usr/bin/env bash
# commands/health.sh — Health dashboard for Sentinels Hub repos

cmd_health() {
  require_deps jq gh curl || return 1

  local org="sentinels-hub"

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --org) org="$2"; shift 2 ;;
      --help|-h)
        echo "Usage: sentinels-toolkit health [--org ORG]"
        echo ""
        echo "Show health dashboard for all repos in a GitHub organization."
        echo ""
        echo "Options:"
        echo "  --org ORG    GitHub org/user (default: sentinels-hub)"
        return 0
        ;;
      *) echo -e "${RED:-}Unknown option: $1${RESET:-}" >&2; return 1 ;;
    esac
  done

  echo -e "${BOLD:-}${CYAN:-}🏥 Sentinels Health Dashboard${RESET:-}"
  echo -e "${DIM:-}Organization: ${org}${RESET:-}"
  echo ""

  # Fetch repos
  local repos_json
  repos_json=$(gh repo list "$org" --json name,pushedAt,description --limit 50 2>/dev/null) || {
    echo -e "${RED:-}ERROR:${RESET:-} Failed to fetch repos from GitHub. Check 'gh auth status'." >&2
    return 1
  }

  local repo_count
  repo_count=$(echo "$repos_json" | jq 'length')

  if [[ "$repo_count" -eq 0 ]]; then
    echo -e "${YELLOW:-}No repositories found for ${org}.${RESET:-}"
    return 0
  fi

  echo -e "${DIM:-}Found ${repo_count} repositories. Fetching details...${RESET:-}"
  echo ""

  # Print table header
  printf "${BOLD:-}%-28s %-10s %-10s %-14s %-20s${RESET:-}\n" \
    "REPOSITORY" "PRs" "CHECKS" "CONTRACT" "LAST PUSH"
  print_hr 82

  # Temp dir for parallel results
  local tmpdir
  tmpdir=$(mktemp -d)
  # Cleanup handled at end of function (not via trap, to avoid scope issues)

  # Fetch details for each repo in parallel
  local i=0
  while IFS= read -r repo_name; do
    (
      local prs_count=0
      local checks_status="—"
      local contract_status="—"
      local pushed_at

      pushed_at=$(echo "$repos_json" | jq -r ".[$i].pushedAt // \"unknown\"" | cut -c1-10)

      # Get open PRs count
      prs_count=$(gh pr list --repo "${org}/${repo_name}" --state open --json number --limit 100 2>/dev/null | jq 'length' 2>/dev/null) || prs_count="?"

      # Get latest commit checks
      local default_branch
      default_branch=$(gh repo view "${org}/${repo_name}" --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null) || default_branch="main"
      local checks_json
      checks_json=$(gh api "repos/${org}/${repo_name}/commits/${default_branch}/check-runs" --jq '.check_runs | map(.conclusion) | unique' 2>/dev/null) || checks_json="[]"

      if echo "$checks_json" | jq -e 'index("failure")' &>/dev/null; then
        checks_status="${RED:-}✗ failing${RESET:-}"
      elif echo "$checks_json" | jq -e 'index("success")' &>/dev/null; then
        checks_status="${GREEN:-}✓ passing${RESET:-}"
      elif echo "$checks_json" | jq -e 'length > 0' &>/dev/null; then
        checks_status="${YELLOW:-}~ mixed${RESET:-}"
      else
        checks_status="${DIM:-}— none${RESET:-}"
      fi

      # Check for contract
      local contract_json
      contract_json=$(gh api "repos/${org}/${repo_name}/contents/.sentinels/contract.json" --jq '.content' 2>/dev/null) || contract_json=""
      if [[ -n "$contract_json" ]]; then
        local decoded
        decoded=$(echo "$contract_json" | base64 -d 2>/dev/null) || decoded=""
        if [[ -n "$decoded" ]]; then
          local cstatus
          cstatus=$(echo "$decoded" | jq -r '.status // "unknown"' 2>/dev/null)
          case "$cstatus" in
            active) contract_status="${GREEN:-}● active${RESET:-}" ;;
            closed) contract_status="${DIM:-}○ closed${RESET:-}" ;;
            *) contract_status="${YELLOW:-}? ${cstatus}${RESET:-}" ;;
          esac
        fi
      fi

      # Format PRs with color
      local prs_display
      if [[ "$prs_count" == "0" ]]; then
        prs_display="${DIM:-}0${RESET:-}"
      elif [[ "$prs_count" == "?" ]]; then
        prs_display="${DIM:-}?${RESET:-}"
      else
        prs_display="${YELLOW:-}${prs_count}${RESET:-}"
      fi

      # Write result to temp file (for ordering)
      printf "%-28s %-22s %-22s %-26s %-20s\n" \
        "$repo_name" "$prs_display" "$checks_status" "$contract_status" "$pushed_at" \
        > "$tmpdir/$i"
    ) &

    i=$((i + 1))
  done < <(echo "$repos_json" | jq -r '.[].name')

  # Wait for all background jobs
  wait

  # Print results in order
  for ((j = 0; j < i; j++)); do
    if [[ -f "$tmpdir/$j" ]]; then
      echo -e "$(cat "$tmpdir/$j")"
    fi
  done

  echo ""
  print_hr 82
  echo -e "${DIM:-}Total: ${repo_count} repos${RESET:-}"

  rm -rf "$tmpdir"
}
