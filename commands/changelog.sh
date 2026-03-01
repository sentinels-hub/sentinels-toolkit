#!/usr/bin/env bash
# commands/changelog.sh — Changelog generator from conventional commits

cmd_changelog() {
  local repo_path="."
  local since_tag=""
  local output_file="CHANGELOG.md"
  local use_stdout=false

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) repo_path="$2"; shift 2 ;;
      --since) since_tag="$2"; shift 2 ;;
      --output) output_file="$2"; shift 2 ;;
      --stdout) use_stdout=true; shift ;;
      --help|-h)
        cat <<EOF
Usage: sentinels-toolkit changelog [options]

Generate a changelog from conventional commits.

Options:
  --repo PATH     Path to git repository (default: .)
  --since TAG     Generate changelog since this tag
  --output FILE   Output file (default: CHANGELOG.md)
  --stdout        Print to stdout instead of writing file
  --help          Show this help
EOF
        return 0
        ;;
      *) echo -e "${RED:-}Unknown option: $1${RESET:-}" >&2; return 1 ;;
    esac
  done

  # Validate repo
  if [[ ! -d "$repo_path/.git" ]]; then
    echo -e "${RED:-}ERROR:${RESET:-} Not a git repository: ${repo_path}" >&2
    return 1
  fi

  echo -e "${BOLD:-}${CYAN:-}📋 Generating Changelog${RESET:-}" >&2

  # Build git log command
  local log_range=""
  if [[ -n "$since_tag" ]]; then
    # Verify tag exists
    if ! git -C "$repo_path" rev-parse "$since_tag" &>/dev/null; then
      echo -e "${RED:-}ERROR:${RESET:-} Tag '${since_tag}' not found." >&2
      return 1
    fi
    log_range="${since_tag}..HEAD"
  fi

  # Get git log with conventional commit format
  local git_log
  git_log=$(git -C "$repo_path" log $log_range \
    --pretty=format:"%H|%s|%an|%ai|%D" \
    --no-merges 2>/dev/null) || {
    echo -e "${RED:-}ERROR:${RESET:-} Failed to read git log." >&2
    return 1
  }

  if [[ -z "$git_log" ]]; then
    echo -e "${YELLOW:-}No commits found.${RESET:-}" >&2
    return 0
  fi

  # Generate changelog content
  local changelog=""
  changelog+="# Changelog"$'\n'
  changelog+=""$'\n'

  # Collect tags for version grouping
  local current_version="Unreleased"
  local version_date=""
  local has_content=false

  # Category arrays
  declare -A categories
  categories=(
    [feat]="🚀 Features"
    [fix]="🐛 Bug Fixes"
    [docs]="📚 Documentation"
    [style]="💅 Style"
    [refactor]="♻️  Refactoring"
    [perf]="⚡ Performance"
    [test]="🧪 Tests"
    [build]="🏗️  Build"
    [ci]="🔧 CI/CD"
    [chore]="🔨 Chores"
  )

  # Category order
  local category_order=(feat fix docs style refactor perf test build ci chore)

  # Temp storage for commits per version per category
  local tmpdir
  tmpdir=$(mktemp -d)
  # Cleanup handled at end of function (not via trap, to avoid scope issues)

  mkdir -p "$tmpdir/$current_version"

  while IFS='|' read -r hash subject author date refs; do
    [[ -z "$hash" ]] && continue

    # Check if this commit has a tag
    if [[ -n "$refs" ]]; then
      local tag_match
      tag_match=$(echo "$refs" | grep -oE 'tag: [^ ,)]+' | head -1 | sed 's/tag: //' || true)
      if [[ -n "$tag_match" ]]; then
        current_version="$tag_match"
        version_date=$(echo "$date" | cut -c1-10)
        mkdir -p "$tmpdir/$current_version"
      fi
    fi

    # Parse conventional commit type
    local commit_type=""
    local scope=""
    local description="$subject"

    local cc_regex='^([a-z]+)(\(([^)]+)\))?!?:[[:space:]](.+)$'
    if [[ "$subject" =~ $cc_regex ]]; then
      commit_type="${BASH_REMATCH[1]}"
      scope="${BASH_REMATCH[3]}"
      description="${BASH_REMATCH[4]}"
    fi

    # Default to "other" if not conventional
    if [[ -z "$commit_type" ]]; then
      commit_type="chore"
    fi

    # Normalize type
    case "$commit_type" in
      feat|fix|docs|style|refactor|perf|test|build|ci|chore) ;;
      tests) commit_type="test" ;;
      doc) commit_type="docs" ;;
      *) commit_type="chore" ;;
    esac

    # Store commit
    local short_hash="${hash:0:7}"
    local entry="- "
    if [[ -n "$scope" ]]; then
      entry+="**${scope}:** "
    fi
    entry+="${description} (\`${short_hash}\`)"

    echo "$entry" >> "$tmpdir/$current_version/$commit_type"

  done <<< "$git_log"

  # Build changelog from collected data
  local versions=()
  for dir in "$tmpdir"/*/; do
    [[ -d "$dir" ]] || continue
    versions+=("$(basename "$dir")")
  done

  # Sort versions: Unreleased first, then reverse chronological
  local sorted_versions=()
  for v in "${versions[@]}"; do
    if [[ "$v" == "Unreleased" ]]; then
      sorted_versions=("$v" "${sorted_versions[@]}")
    else
      sorted_versions+=("$v")
    fi
  done

  for version in "${sorted_versions[@]}"; do
    local version_dir="$tmpdir/$version"
    local version_has_content=false

    # Check if version has any commits
    for cat in "${category_order[@]}"; do
      if [[ -f "$version_dir/$cat" ]]; then
        version_has_content=true
        break
      fi
    done

    if [[ "$version_has_content" == false ]]; then
      continue
    fi

    # Version header
    if [[ "$version" == "Unreleased" ]]; then
      changelog+="## [Unreleased]"$'\n'
    else
      changelog+="## [${version}]"
      if [[ -n "$version_date" ]]; then
        changelog+=" — ${version_date}"
      fi
      changelog+=$'\n'
    fi
    changelog+=""$'\n'

    # Categories
    for cat in "${category_order[@]}"; do
      if [[ -f "$version_dir/$cat" ]]; then
        local cat_title="${categories[$cat]}"
        changelog+="### ${cat_title}"$'\n'
        changelog+=""$'\n'
        changelog+="$(cat "$version_dir/$cat")"$'\n'
        changelog+=""$'\n'
      fi
    done

    has_content=true
  done

  if [[ "$has_content" == false ]]; then
    echo -e "${YELLOW:-}No conventional commits found.${RESET:-}" >&2
    rm -rf "$tmpdir"
    return 0
  fi

  # Output
  if [[ "$use_stdout" == true ]]; then
    echo "$changelog"
  else
    local full_output_path
    if [[ "$output_file" == /* ]]; then
      full_output_path="$output_file"
    else
      full_output_path="$repo_path/$output_file"
    fi
    echo "$changelog" > "$full_output_path"
    echo -e "${GREEN:-}✓${RESET:-} Changelog written to ${full_output_path}" >&2
  fi

  rm -rf "$tmpdir"
}
