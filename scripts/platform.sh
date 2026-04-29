#!/usr/bin/env bash
# platform.sh — environment checks (bash version, jq, gum, TTY)
# Source me. Do not execute.

fn_platform_require_bash() {
  # macOS default bash is 3.2; we require >= 3.2
  local major minor
  major="${BASH_VERSINFO[0]:-0}"
  minor="${BASH_VERSINFO[1]:-0}"
  if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 2 ]; }; then
    fn_ui_err "bash >= 3.2 required (current: ${BASH_VERSION:-unknown})"
    exit 2
  fi
}

fn_platform_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    fn_ui_err "jq is required (brew install jq)"
    exit 2
  fi
}

fn_platform_require_gum() {
  if ! command -v gum >/dev/null 2>&1; then
    fn_ui_err "gum is required (brew install gum)"
    exit 2
  fi
}

fn_platform_is_tty() {
  [ -t 1 ]
}
