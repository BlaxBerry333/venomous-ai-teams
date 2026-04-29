#!/usr/bin/env bash
# remove.sh — remove a single team from target. __ai__/<team>/ is preserved.
# Source me. Do not execute.

REMOVE_TEAM_SUBDIRS="commands agents hooks templates"

fn_remove_team() {
  local team="$1" target="$2"
  local sub removed=0

  for sub in $REMOVE_TEAM_SUBDIRS; do
    if [ -d "$target/.claude/$sub/$team" ]; then
      rm -rf "$target/.claude/$sub/$team"
      fn_ui_ok "removed .claude/$sub/$team/"
      removed=$((removed+1))
    fi
  done

  if [ -f "$target/.claude/.fragments/$team.json" ]; then
    rm -f "$target/.claude/.fragments/$team.json"
    fn_ui_ok "removed .claude/.fragments/$team.json"
    removed=$((removed+1))
  fi

  if [ -d "$target/__ai__/$team" ]; then
    fn_ui_warn "__ai__/$team/ preserved (your work)"
  fi

  if [ "$removed" -eq 0 ]; then
    fn_ui_warn "no $team artifacts found under .claude/"
  fi
}
