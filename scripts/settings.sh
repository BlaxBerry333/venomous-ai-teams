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
# User-data guard: entries in the existing hooks/permissions that neither the rebuilt
# result nor any fragment shipped by this framework accounts for would be silently
# lost by the rebuild — those are shown and require confirmation before merging
# (pre-merge file kept as settings.json.bak.<timestamp> on confirm). Framework-owned
# entries (any team's fragment, installed here or not) drop silently — that is the
# normal remove/reinstall path, not user data.
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

  # -------- user-data guard (see header) --------
  # lost = old hooks/permissions − rebuilt result − everything any framework
  # fragment could have contributed. Non-empty lost = user-authored entries the
  # rebuild would silently destroy.
  local lost="" diff_rc=0
  if [ -f "$out" ]; then
    local known_tmp="$claude_dir/.settings.known.$$"
    local known_base="$claude_dir/.settings.knownbase.$$"
    local known_frags=() kf
    for kf in "$SCRIPT_DIR"/teams/*/.claude/.fragments/*.json; do
      [ -f "$kf" ] && known_frags+=("$kf")
    done
    printf '{}' > "$known_base"
    # Fallback to {} on any failure: unknown fragments only ever WIDEN the
    # warning (never cause silent loss), so degrading here is safe.
    if [ "${#known_frags[@]}" -eq 0 ] \
      || ! jq -s "$filter" "$known_base" "${known_frags[@]}" > "$known_tmp" 2>/dev/null; then
      printf '{}' > "$known_tmp"
    fi

    local diff_filter='
      def sub_arr($a; $b; $c): (($a // []) - ($b // []) - ($c // []));
      def lost_hooks($o; $n; $k):
        ($o.hooks // {}) | to_entries
        | map((.value = sub_arr(.value; ($n.hooks // {})[.key]; ($k.hooks // {})[.key]))
              | select((.value | length) > 0))
        | from_entries;
      def lost_perms($o; $n; $k):
        ($o.permissions // {}) | to_entries
        | map(. as $e
              | (if ($e.key == "allow" or $e.key == "deny")
                 then ($e | .value = sub_arr($e.value; ($n.permissions // {})[$e.key]; ($k.permissions // {})[$e.key]))
                 elif ((($n.permissions // {}) | has($e.key)) and (($n.permissions // {})[$e.key] == $e.value))
                 then ($e | .value = [])
                 else $e end)
              | select(if (.value | type) == "array" then (.value | length) > 0 else true end))
        | from_entries;
      { hooks: lost_hooks($old[0]; $new[0]; $known[0]),
        permissions: lost_perms($old[0]; $new[0]; $known[0]) }
      | if ((.hooks | length) == 0) and ((.permissions | length) == 0) then empty else . end
    '
    set +e
    lost=$(jq -n --slurpfile old "$out" --slurpfile new "$tmp" --slurpfile known "$known_tmp" "$diff_filter" 2>/dev/null)
    diff_rc=$?
    set -e
    rm -f "$known_tmp" "$known_base"
  fi

  if [ "$diff_rc" -ne 0 ] || [ -n "$lost" ]; then
    if [ "$diff_rc" -ne 0 ]; then
      fn_ui_warn "cannot verify existing hooks/permissions (unexpected shape) — merge rebuilds them from fragments"
    else
      fn_ui_warn "settings.json has hooks/permissions entries no framework team provides — merge will DROP:"
      local lost_line
      while IFS= read -r lost_line; do
        fn_ui_line "    $lost_line"
      done <<EOF
$lost
EOF
    fi
    fn_ui_lines \
      "  hooks/permissions in settings.json are framework-managed (rebuilt on every merge)." \
      "  Personal config belongs in .claude/settings.local.json — this tool never touches it."
    if ! fn_ui_confirm "Discard the entries above and continue?"; then
      rm -f "$tmp" "$base_tmp"
      fn_safety_restore_settings "$target"
      fn_ui_lines \
        "settings.json left unchanged (team files were already updated)." \
        "Move your entries to .claude/settings.local.json, then re-run setup.sh to finish."
      fn_ui_cancelled
      exit 0
    fi
    local keep="$claude_dir/settings.json.bak.$(date +%Y%m%d%H%M%S)"
    cp "$out" "$keep"
    fn_ui_ok "pre-merge settings kept (${keep#"$target"/})"
  fi

  mv "$tmp" "$out"
  rm -f "$base_tmp"
  fn_safety_clear_settings_backup "$target"

  fn_ui_ok "settings.json (merged ${#frags[@]} fragment(s))"
}
