#!/usr/bin/env bash
# install.sh — install / reinstall a single team into target.
# Source me. Do not execute.
#
# fn_install_team <team> <target> <mode>   # mode = install | reinstall
#
# Layout (source 1:1 mirrors install destination):
#   teams/<team>/.claude/commands/<team>.md   (optional: team entry, /<team>)
#   teams/<team>/.claude/commands/<team>/
#   teams/<team>/.claude/agents/<team>/
#   teams/<team>/.claude/hooks/<team>/
#   teams/<team>/.claude/templates/<team>/    (optional)
#   teams/<team>/.claude/.fragments/<team>.json
#   teams/<team>/__ai__/<team>/               (optional starter; absent → mkdir empty)
#
# Failure model: reinstall stages old content as <name>.bak.<id> via mv (atomic
# rename), copies new content INCLUDING __ai__/<team>/ skeleton, then drops the
# bak only after every step succeeds (commit point). Any failure before commit
# triggers rollback to restore prior state. Initial install rolls back any
# partial cp by removing freshly-created <team>/ subdirs.

# Subdirs under .claude/ that hold per-team content (kebab list).
INSTALL_TEAM_SUBDIRS="commands agents hooks templates"

fn_install_team() {
  local team="$1" target="$2" mode="$3"
  local src="$SCRIPT_DIR/teams/$team"

  if [ ! -d "$src/.claude" ]; then
    fn_ui_err "team source not found" "$src/.claude"
    exit 2
  fi

  if ! mkdir -p "$target/.claude/.fragments"; then
    fn_ui_err "failed to create .claude/.fragments/ (path blocked? permission?)"
    exit 2
  fi

  local stash_id="$$.$RANDOM.$(date +%s)"
  local stash_subs=""        # subs whose old <team>/ was stashed as bak (reinstall only)
  local stash_frag=0         # 1 if old .fragments/<team>.json was stashed (reinstall only)
  local stash_entry=0        # 1 if old commands/<team>.md was stashed (reinstall only)
  local installed_subs=""    # subs where we successfully cp'd new <team>/ (rollback removes)
  local installed_frag=0     # 1 if we successfully cp'd new .fragments/<team>.json
  local installed_entry=0    # 1 if we successfully cp'd new commands/<team>.md
  local ai_pristine=0        # 1 if __ai__/<team>/ was created by this run; rollback removes
  local rollback_done=0

  # Clean any leftover .bak.* from prior failed runs (e.g. partial rollback).
  # Without this, a residue would block our mv on retry with no clear cause.
  if [ -d "$target/.claude" ]; then
    local cleanup_sub
    for cleanup_sub in $INSTALL_TEAM_SUBDIRS; do
      if [ -d "$target/.claude/$cleanup_sub" ]; then
        find "$target/.claude/$cleanup_sub" -maxdepth 1 -type d -name ".${team}.bak.*" -exec rm -rf {} + 2>/dev/null || true
      fi
    done
    if [ -d "$target/.claude/.fragments" ]; then
      find "$target/.claude/.fragments" -maxdepth 1 -type f -name ".${team}.json.bak.*" -delete 2>/dev/null || true
    fi
    if [ -d "$target/.claude/commands" ]; then
      find "$target/.claude/commands" -maxdepth 1 -type f -name ".${team}.md.bak.*" -delete 2>/dev/null || true
    fi
  fi

  # Roll back to pre-install state. Called on any failure.
  # Strategy: remove anything we cp'd this run (installed_*), then restore stashed bak (stash_*).
  # Subs may appear in both lists (reinstall path); union handles that — rm is idempotent.
  _fn_install_rollback() {
    [ "$rollback_done" -eq 1 ] && return 0
    rollback_done=1
    local sub seen
    # 1. Remove freshly-copied .claude/<sub>/<team>/ (covers fresh install + reinstall partial)
    local all_subs="$installed_subs $stash_subs"
    local processed=""
    for sub in $all_subs; do
      # de-dup
      case " $processed " in *" $sub "*) continue ;; esac
      processed="$processed $sub"
      if [ -d "$target/.claude/$sub/$team" ]; then
        rm -rf "$target/.claude/$sub/$team" 2>/dev/null || true
      fi
    done
    # 2. Remove freshly-copied .fragments/<team>.json (fresh install or reinstall)
    if [ "$installed_frag" -eq 1 ] || [ "$stash_frag" -eq 1 ]; then
      rm -f "$target/.claude/.fragments/$team.json" 2>/dev/null || true
    fi
    # 2b. Remove freshly-copied commands/<team>.md entry file
    if [ "$installed_entry" -eq 1 ] || [ "$stash_entry" -eq 1 ]; then
      rm -f "$target/.claude/commands/$team.md" 2>/dev/null || true
    fi
    # 3. Restore stashed bak (reinstall only)
    for sub in $stash_subs; do
      if [ -d "$target/.claude/$sub/.${team}.bak.${stash_id}" ]; then
        mv "$target/.claude/$sub/.${team}.bak.${stash_id}" "$target/.claude/$sub/$team" 2>/dev/null || true
      fi
    done
    if [ "$stash_frag" -eq 1 ]; then
      if [ -f "$target/.claude/.fragments/.${team}.json.bak.${stash_id}" ]; then
        mv "$target/.claude/.fragments/.${team}.json.bak.${stash_id}" "$target/.claude/.fragments/$team.json" 2>/dev/null || true
      fi
    fi
    if [ "$stash_entry" -eq 1 ]; then
      if [ -f "$target/.claude/commands/.${team}.md.bak.${stash_id}" ]; then
        mv "$target/.claude/commands/.${team}.md.bak.${stash_id}" "$target/.claude/commands/$team.md" 2>/dev/null || true
      fi
    fi
    # 4. Clean partial __ai__/<team>/ only if this run created it (was missing before)
    if [ "$ai_pristine" -eq 1 ] && [ -d "$target/__ai__/$team" ]; then
      rm -rf "$target/__ai__/$team" 2>/dev/null || true
    fi
  }

  # Stash existing artifacts (reinstall only). Rename is atomic on same filesystem.
  if [ "$mode" = "reinstall" ]; then
    local sub
    for sub in $INSTALL_TEAM_SUBDIRS; do
      if [ -d "$target/.claude/$sub/$team" ]; then
        if ! mv "$target/.claude/$sub/$team" "$target/.claude/$sub/.${team}.bak.${stash_id}"; then
          fn_ui_err "failed to stash existing .claude/$sub/$team/ (permission?)"
          _fn_install_rollback
          exit 2
        fi
        stash_subs="$stash_subs $sub"
      fi
    done
    if [ -f "$target/.claude/.fragments/$team.json" ]; then
      if ! mv "$target/.claude/.fragments/$team.json" "$target/.claude/.fragments/.${team}.json.bak.${stash_id}"; then
        fn_ui_err "failed to stash existing .fragments/$team.json"
        _fn_install_rollback
        exit 2
      fi
      stash_frag=1
    fi
    if [ -f "$target/.claude/commands/$team.md" ]; then
      if ! mv "$target/.claude/commands/$team.md" "$target/.claude/commands/.${team}.md.bak.${stash_id}"; then
        fn_ui_err "failed to stash existing commands/$team.md"
        _fn_install_rollback
        exit 2
      fi
      stash_entry=1
    fi
  fi

  # Copy new team subdirs. Any cp failure triggers rollback.
  local copied=0 sub
  for sub in $INSTALL_TEAM_SUBDIRS; do
    local src_sub="$src/.claude/$sub/$team"
    if [ -d "$src_sub" ]; then
      if ! mkdir -p "$target/.claude/$sub"; then
        fn_ui_err "failed to create .claude/$sub/"
        _fn_install_rollback
        exit 2
      fi
      # Register before cp so rollback cleans any partial write on failure.
      installed_subs="$installed_subs $sub"
      if ! cp -R "$src_sub" "$target/.claude/$sub/"; then
        fn_ui_err "failed to copy .claude/$sub/$team/ (permission? disk full?)"
        _fn_install_rollback
        exit 2
      fi
      fn_ui_ok ".claude/$sub/$team/"
      copied=$((copied+1))
    fi
  done

  # hooks: chmod +x for any .sh (best-effort; warn on failure since unexecutable
  # hooks fail silently at trigger time and are hard to diagnose).
  if [ -d "$target/.claude/hooks/$team" ]; then
    if ! find "$target/.claude/hooks/$team" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null; then
      fn_ui_warn "chmod +x failed for some hooks/$team/*.sh — they may not run"
    fi
  fi

  # Copy fragment
  local src_frag="$src/.claude/.fragments/$team.json"
  if [ -f "$src_frag" ]; then
    # Register before cp so rollback cleans any partial write on failure.
    installed_frag=1
    if ! cp "$src_frag" "$target/.claude/.fragments/$team.json"; then
      fn_ui_err "failed to copy .fragments/$team.json"
      _fn_install_rollback
      exit 2
    fi
    fn_ui_ok ".claude/.fragments/$team.json"
  else
    fn_ui_warn "no .fragments/$team.json in source — settings will not include $team-specific hooks/permissions"
  fi

  # Copy team entry file commands/<team>.md (optional). Triggers /<team> directly.
  local src_entry="$src/.claude/commands/$team.md"
  if [ -f "$src_entry" ]; then
    if ! mkdir -p "$target/.claude/commands"; then
      fn_ui_err "failed to create .claude/commands/"
      _fn_install_rollback
      exit 2
    fi
    installed_entry=1
    if ! cp "$src_entry" "$target/.claude/commands/$team.md"; then
      fn_ui_err "failed to copy commands/$team.md"
      _fn_install_rollback
      exit 2
    fi
    fn_ui_ok ".claude/commands/$team.md"
  fi

  # __ai__/<team>/ : never overwrite user work. Source dir absent → mkdir empty.
  # Source dir present (team ships starter files) → cp -R.
  # Failure here triggers rollback so user's original .claude/<team>/ is restored.
  local src_ai="$src/__ai__/$team"
  if ! mkdir -p "$target/__ai__"; then
    fn_ui_err "failed to create __ai__/ (permission?)"
    _fn_install_rollback
    exit 2
  fi
  if [ -d "$target/__ai__/$team" ]; then
    fn_ui_warn "__ai__/$team/ exists — preserved (not overwritten)"
  elif [ -d "$src_ai" ]; then
    ai_pristine=1
    if ! cp -R "$src_ai" "$target/__ai__/"; then
      fn_ui_err "failed to copy __ai__/$team/ starter (disk full? permission?)"
      _fn_install_rollback
      exit 2
    fi
    fn_ui_ok "__ai__/$team/ (starter)"
  else
    ai_pristine=1
    if ! mkdir -p "$target/__ai__/$team"; then
      fn_ui_err "failed to create __ai__/$team/ (permission?)"
      _fn_install_rollback
      exit 2
    fi
    fn_ui_ok "__ai__/$team/ (created)"
  fi

  # All copies succeeded — commit point: drop stashed bak.
  if [ "$mode" = "reinstall" ]; then
    local sub
    for sub in $stash_subs; do
      rm -rf "$target/.claude/$sub/.${team}.bak.${stash_id}" 2>/dev/null || true
    done
    if [ "$stash_frag" -eq 1 ]; then
      rm -f "$target/.claude/.fragments/.${team}.json.bak.${stash_id}" 2>/dev/null || true
    fi
    if [ "$stash_entry" -eq 1 ]; then
      rm -f "$target/.claude/commands/.${team}.md.bak.${stash_id}" 2>/dev/null || true
    fi
  fi

  if [ "$copied" -eq 0 ]; then
    fn_ui_warn "team $team has no .claude/ subdirs to install"
  fi
}
