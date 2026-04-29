#!/usr/bin/env bash
# safety.sh — path blacklist, framework self-protection, settings backup/restore.
# Source me. Do not execute.

# fn_safety_check_target <path>
# - path exists & is dir
# - not in system blacklist
# - not $HOME root
# - not framework dir itself or its children
# Echoes the resolved absolute path on success. Exits 1 on failure.
fn_safety_check_target() {
  local input="$1" abs
  if [ -z "$input" ]; then
    fn_ui_err "target path is empty"
    exit 1
  fi
  if [ ! -d "$input" ]; then
    fn_ui_err "target directory does not exist" "$input"
    exit 1
  fi
  if ! abs=$(cd "$input" 2>/dev/null && pwd); then
    fn_ui_err "cannot resolve absolute path" "$input"
    exit 1
  fi

  case "$abs" in
    /|/Users|/home|/etc|/var|/usr|/bin|/sbin|/tmp)
      fn_ui_err "refuse to install into system directory" "$abs"
      exit 1
      ;;
  esac
  if [ "$abs" = "$HOME" ]; then
    fn_ui_err "refuse to install into \$HOME root" "$abs"
    exit 1
  fi
  if [ "$abs" = "$SCRIPT_DIR" ]; then
    fn_ui_err "refuse to install into framework directory itself" "$abs"
    exit 1
  fi
  case "$abs/" in
    "$SCRIPT_DIR"/*)
      # framework subdirs are fine ONLY for __playground__/ (local testing)
      case "$abs" in
        "$SCRIPT_DIR"/__playground__|"$SCRIPT_DIR"/__playground__/*)
          ;;
        *)
          fn_ui_err "refuse to install into framework subdirectory" "$abs"
          exit 1
          ;;
      esac
      ;;
  esac

  printf "%s" "$abs"
}

fn_safety_backup_settings() {
  local target="$1"
  if [ -f "$target/.claude/settings.json" ]; then
    cp "$target/.claude/settings.json" "$target/.claude/settings.json.bak"
  fi
}

fn_safety_restore_settings() {
  local target="$1"
  if [ -f "$target/.claude/settings.json.bak" ]; then
    mv "$target/.claude/settings.json.bak" "$target/.claude/settings.json"
  fi
}

fn_safety_clear_settings_backup() {
  local target="$1"
  rm -f "$target/.claude/settings.json.bak"
}
