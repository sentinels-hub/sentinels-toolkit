#!/usr/bin/env bash
# lib/table.sh — Table and formatting utilities

# Print a horizontal rule
# Usage: print_hr [width] [char]
print_hr() {
  local width="${1:-60}"
  local char="${2:-─}"
  local line=""
  for ((i = 0; i < width; i++)); do
    line+="$char"
  done
  echo -e "${DIM:-}${line}${RESET:-}"
}

# Print a box header
# Usage: print_box_header "Title" [width]
print_box_header() {
  local title="$1"
  local width="${2:-60}"
  local padding=$(( (width - ${#title} - 2) / 2 ))
  local pad_left="" pad_right=""
  for ((i = 0; i < padding; i++)); do pad_left+="─"; done
  for ((i = 0; i < padding; i++)); do pad_right+="─"; done
  # Adjust for odd lengths
  if (( (width - ${#title} - 2) % 2 == 1 )); then
    pad_right+="─"
  fi
  echo -e "${BOLD:-}${CYAN:-}╭${pad_left} ${title} ${pad_right}╮${RESET:-}"
}

# Print a box line
# Usage: print_box_line "content" [width]
print_box_line() {
  local content="$1"
  local width="${2:-60}"
  # Strip ANSI codes for length calculation
  local stripped
  stripped=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
  local content_len=${#stripped}
  local padding=$(( width - content_len - 4 ))
  local pad=""
  if (( padding > 0 )); then
    for ((i = 0; i < padding; i++)); do pad+=" "; done
  fi
  echo -e "${CYAN:-}│${RESET:-} ${content}${pad} ${CYAN:-}│${RESET:-}"
}

# Print a box footer
# Usage: print_box_footer [width]
print_box_footer() {
  local width="${1:-60}"
  local line=""
  for ((i = 0; i < width - 2; i++)); do line+="─"; done
  echo -e "${BOLD:-}${CYAN:-}╰${line}╯${RESET:-}"
}

# Print a key-value pair
# Usage: print_kv "Key" "Value"
print_kv() {
  local key="$1"
  local value="$2"
  local key_width="${3:-16}"
  printf "  ${DIM:-}%-${key_width}s${RESET:-} %s\n" "$key" "$value"
}

# Print a table header row
# Usage: print_table_header "Col1" "Col2" "Col3" ...
print_table_header() {
  local header=""
  for col in "$@"; do
    header+="$(printf "${BOLD:-}%-18s${RESET:-}" "$col")"
  done
  echo -e "$header"
  print_hr $(( 18 * $# ))
}

# Print a table row
# Usage: print_table_row "Val1" "Val2" "Val3" ...
print_table_row() {
  local row=""
  for col in "$@"; do
    row+="$(printf "%-18s" "$col")"
  done
  echo -e "$row"
}

# Print a status badge
# Usage: print_status "passed" → green, "failed" → red, etc.
print_status() {
  local status="$1"
  case "$status" in
    passed|pass|ok|success)
      echo -e "${GREEN:-}● passed${RESET:-}" ;;
    failed|fail|error)
      echo -e "${RED:-}● failed${RESET:-}" ;;
    pending|waiting)
      echo -e "${DIM:-}○ pending${RESET:-}" ;;
    skipped|skip)
      echo -e "${YELLOW:-}◐ skipped${RESET:-}" ;;
    active|running)
      echo -e "${BLUE:-}◉ active${RESET:-}" ;;
    *)
      echo -e "${DIM:-}? ${status}${RESET:-}" ;;
  esac
}
