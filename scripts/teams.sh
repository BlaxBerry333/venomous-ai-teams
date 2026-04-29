#!/usr/bin/env bash
# teams.sh — available team listing + __ai__/__teams__.txt management.
# Source me. Do not execute.
#
# Requires: $SCRIPT_DIR (framework root)

TEAMS_RECORD_FILE="__ai__/__teams__.txt"

# Team metadata. Format: name|icon
# Description lives in teams/<team>/README.md (per spec: simple icon+name in selector).
TEAMS_DEFS="web-dev-team|🔨"

# Echo each available team name on its own line.
fn_teams_list_available() {
  local def name
  while IFS='|' read -r name _; do
    [ -z "$name" ] && continue
    [ -d "$SCRIPT_DIR/teams/$name" ] || continue
    printf "%s\n" "$name"
  done <<< "$TEAMS_DEFS"
}

# Echo "<icon> <name>" lines for selector display.
fn_teams_list_available_pretty() {
  local name icon
  while IFS='|' read -r name icon; do
    [ -z "$name" ] && continue
    [ -d "$SCRIPT_DIR/teams/$name" ] || continue
    printf "%s %s\n" "$icon" "$name"
  done <<< "$TEAMS_DEFS"
}

# fn_teams_list_installed <target> -> echo each installed team on its own line.
fn_teams_list_installed() {
  local target="$1"
  local file="$target/$TEAMS_RECORD_FILE"
  [ -f "$file" ] || return 0
  # filter out blank lines
  grep -v '^[[:space:]]*$' "$file" 2>/dev/null || true
}

# fn_teams_is_installed <team> <target> -> 0 yes / 1 no
fn_teams_is_installed() {
  local team="$1" target="$2"
  local file="$target/$TEAMS_RECORD_FILE"
  [ -f "$file" ] || return 1
  grep -Fxq "$team" "$file" 2>/dev/null
}

# fn_teams_record_add <team> <target>
fn_teams_record_add() {
  local team="$1" target="$2"
  local file="$target/$TEAMS_RECORD_FILE"
  mkdir -p "$(dirname "$file")"
  if [ ! -f "$file" ]; then
    : > "$file"
  fi
  if ! grep -Fxq "$team" "$file" 2>/dev/null; then
    printf "%s\n" "$team" >> "$file"
  fi
}

# fn_teams_record_remove <team> <target>
fn_teams_record_remove() {
  local team="$1" target="$2"
  local file="$target/$TEAMS_RECORD_FILE"
  [ -f "$file" ] || return 0
  local tmp="$file.tmp.$$"
  grep -Fxv "$team" "$file" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$file"
}
