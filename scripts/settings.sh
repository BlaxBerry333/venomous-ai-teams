#!/usr/bin/env bash
# settings.sh — merge .claude/.fragments/*.json into .claude/settings.json via jq.
# Source me. Do not execute.
#
# Merge rules:
#   - hooks: deep merge by event; matcher arrays concatenated
#   - permissions.allow / .deny: concatenated + unique
#   - other top-level keys: preserved from existing settings.json (user-owned)
#
# IMPORTANT: settings.json's `hooks` and `permissions` fields are FRAMEWORK-MANAGED.
# User-authored hooks/permissions belong in .claude/settings.local.json (Claude Code's
# native user-override file), which this framework never touches.
#
# On any failure: restore .bak and exit 2.

fn_settings_merge() {
  local target="$1"
  local claude_dir="$target/.claude"
  local frags_dir="$claude_dir/.fragments"
  local out="$claude_dir/settings.json"
  local tmp="$claude_dir/settings.json.tmp.$$"

  mkdir -p "$claude_dir"
  fn_safety_backup_settings "$target"

  # Collect fragment files (bash 3.2: explicit indexed array)
  local frags=()
  if [ -d "$frags_dir" ]; then
    local f
    for f in "$frags_dir"/*.json; do
      [ -f "$f" ] && frags+=("$f")
    done
  fi

  # Base file: existing settings.json minus hooks/permissions (preserve user keys)
  local base_tmp="$claude_dir/.settings.base.$$"
  if [ -f "$out" ]; then
    if ! jq 'del(.hooks) | del(.permissions)' "$out" > "$base_tmp" 2>/dev/null; then
      fn_ui_err "existing settings.json is invalid JSON; aborting merge"
      rm -f "$base_tmp"
      fn_safety_restore_settings "$target"
      exit 2
    fi
  else
    printf '{}' > "$base_tmp"
  fi

  # Build full input file list: base + fragments
  local inputs=("$base_tmp")
  if [ "${#frags[@]}" -gt 0 ]; then
    inputs+=("${frags[@]}")
  fi

  local filter='
    def merge_hooks(a; b):
      reduce ((b // {}) | to_entries[]) as $kv ((a // {});
        .[$kv.key] = ((.[$kv.key] // []) + ($kv.value // [])));
    def uniq_concat(a; b): ((a // []) + (b // []) | unique);
    .[0] as $base
    | reduce .[1:][] as $f ($base;
        .hooks = merge_hooks(.hooks; $f.hooks)
        | .permissions.allow = uniq_concat(.permissions.allow; $f.permissions.allow)
        | .permissions.deny  = uniq_concat(.permissions.deny;  $f.permissions.deny)
      )
    | if (.permissions.allow // [] | length) == 0 then del(.permissions.allow) else . end
    | if (.permissions.deny  // [] | length) == 0 then del(.permissions.deny)  else . end
    | if (.permissions // {} | length) == 0 then del(.permissions) else . end
    | if (.hooks // {} | length) == 0 then del(.hooks) else . end
  '

  if ! jq -s "$filter" "${inputs[@]}" > "$tmp" 2>/dev/null; then
    fn_ui_err "settings.json merge failed (jq error); restoring backup"
    rm -f "$tmp" "$base_tmp"
    fn_safety_restore_settings "$target"
    exit 2
  fi

  if [ ! -s "$tmp" ]; then
    fn_ui_err "settings.json merge produced empty output; restoring backup"
    rm -f "$tmp" "$base_tmp"
    fn_safety_restore_settings "$target"
    exit 2
  fi

  mv "$tmp" "$out"
  rm -f "$base_tmp"
  fn_safety_clear_settings_backup "$target"

  fn_ui_ok "settings.json (merged ${#frags[@]} fragment(s))"
}
