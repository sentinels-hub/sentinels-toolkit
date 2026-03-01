#!/usr/bin/env bash
# lib/colors.sh — ANSI color definitions with TTY detection
# shellcheck disable=SC2034

_sentinels_init_colors() {
  if [[ -t 1 ]] && [[ "${NO_COLOR:-}" == "" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    RESET='\033[0m'
    # Bright variants
    BRIGHT_RED='\033[1;31m'
    BRIGHT_GREEN='\033[1;32m'
    BRIGHT_YELLOW='\033[1;33m'
    BRIGHT_BLUE='\033[1;34m'
    BRIGHT_CYAN='\033[1;36m'
  else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    BOLD=''
    DIM=''
    UNDERLINE=''
    RESET=''
    BRIGHT_RED=''
    BRIGHT_GREEN=''
    BRIGHT_YELLOW=''
    BRIGHT_BLUE=''
    BRIGHT_CYAN=''
  fi
}

_sentinels_init_colors
