#!/usr/bin/env bash
# lib/deps.sh — Dependency validation

require_deps() {
  local missing=()
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED:-}ERROR:${RESET:-} Missing required dependencies: ${missing[*]}" >&2
    echo "Install them and try again." >&2
    return 1
  fi
  return 0
}
