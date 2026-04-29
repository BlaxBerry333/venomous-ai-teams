#!/usr/bin/env bash
# setup.sh — Venomous AI Teams installer (interactive only).
# Pure orchestration; all logic lives in scripts/*.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=scripts/ui.sh
source "$SCRIPT_DIR/scripts/ui.sh"
# shellcheck source=scripts/platform.sh
source "$SCRIPT_DIR/scripts/platform.sh"
# shellcheck source=scripts/safety.sh
source "$SCRIPT_DIR/scripts/safety.sh"
# shellcheck source=scripts/teams.sh
source "$SCRIPT_DIR/scripts/teams.sh"
# shellcheck source=scripts/settings.sh
source "$SCRIPT_DIR/scripts/settings.sh"
# shellcheck source=scripts/install.sh
source "$SCRIPT_DIR/scripts/install.sh"
# shellcheck source=scripts/remove.sh
source "$SCRIPT_DIR/scripts/remove.sh"

fn_ui_init

# EXIT trap: print closure node on abnormal termination. UI_CLOSED is initialized
# in fn_ui_init; it's set to 1 by fn_ui_done / fn_ui_cancelled / fn_ui_aborted to
# prevent double-closure.
_fn_setup_exit_trap() {
  local rc=$?
  if [ "$rc" -ne 0 ] && [ "$UI_CLOSED" -eq 0 ]; then
    fn_ui_aborted
  fi
}
trap _fn_setup_exit_trap EXIT

fn_platform_require_bash
fn_platform_require_jq
fn_platform_require_gum

fn_ui_title "Venomous AI Teams"

# -------------------- helpers --------------------

# fn_pick_team <prompt> <name1> <name2> ...
# Writes chosen team name to global $UI_RESULT, returns 0 on success / 1 on cancel.
# Internally builds "<icon> <name>" labels then maps the chosen label back to the
# original team name (by exact match, not by string splitting — so team names
# containing spaces would still be safe if ever introduced).
fn_pick_team() {
  local prompt="$1"; shift
  local names=("$@")
  local labels=() name icon
  for name in "${names[@]}"; do
    icon=""
    while IFS='|' read -r dn di; do
      [ "$dn" = "$name" ] && { icon="$di"; break; }
    done <<< "$TEAMS_DEFS"
    if [ -n "$icon" ]; then
      labels+=("$icon $name")
    else
      labels+=("$name")
    fi
  done

  fn_ui_select "$prompt" "${labels[@]}" || return 1
  local chosen="$UI_RESULT"

  # Reverse map by exact label match. Pair index between labels[] and names[]
  # is preserved by construction.
  local i
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$chosen" ]; then
      UI_RESULT="${names[$i]}"
      return 0
    fi
  done

  # Should be unreachable — gum returns one of the offered labels verbatim.
  fn_ui_err "internal: chosen label not in offered set" "$chosen"
  return 1
}

# -------------------- fn_flow_install --------------------
fn_flow_install() {
  local available installed_in_target candidate_names=() name
  available=$(fn_teams_list_available)
  if [ -z "$available" ]; then
    fn_ui_err "no teams available in framework"
    exit 2
  fi

  local target_input target
  fn_ui_input "Target project path" "e.g. ~/myproject or absolute path" || { fn_ui_cancelled; exit 0; }
  target_input="$UI_RESULT"
  target=$(fn_safety_check_target "$target_input")

  installed_in_target=$(fn_teams_list_installed "$target")

  # Build candidate list (all available; reinstall is allowed)
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    candidate_names+=("$name")
  done <<< "$available"

  local team
  fn_pick_team "Pick a team" "${candidate_names[@]}" || { fn_ui_cancelled; exit 0; }
  team="$UI_RESULT"

  local mode="install"
  if fn_teams_is_installed "$team" "$target"; then
    mode="reinstall"
    fn_ui_node "$team is already installed in this target. Reinstalling will:"
    fn_ui_lines \
      "  • Replace .claude/commands/$team/" \
      "  • Replace .claude/agents/$team/" \
      "  • Replace .claude/hooks/$team/" \
      "  • Replace .claude/.fragments/$team.json" \
      "  • Re-merge settings.json" \
      "  • Preserve __ai__/$team/ (your work)"
    fn_ui_blank
  else
    fn_ui_node "Confirm"
    fn_ui_lines \
      "    Action  install" \
      "    Team    $team" \
      "    Target  $target"
    fn_ui_blank
  fi

  if ! fn_ui_confirm; then
    fn_ui_cancelled
    exit 0
  fi

  fn_install_team "$team" "$target" "$mode"
  # Record FIRST: install_team has reached its commit point (.claude/<team>/ on disk).
  # If settings_merge later fails, the team is still recorded so a retry detects it
  # as already-installed and uses reinstall (with stash protection).
  fn_teams_record_add "$team" "$target"
  fn_settings_merge "$target"

  fn_ui_done
  fn_ui_docs_links
}

# -------------------- fn_flow_remove --------------------
fn_flow_remove() {
  local target_input target
  fn_ui_input "Target project path" "e.g. ~/myproject or absolute path" || { fn_ui_cancelled; exit 0; }
  target_input="$UI_RESULT"
  target=$(fn_safety_check_target "$target_input")

  local installed names=() name
  installed=$(fn_teams_list_installed "$target")
  if [ -z "$installed" ]; then
    fn_ui_err "no team installed in target" "$target"
    exit 1
  fi

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    names+=("$name")
  done <<< "$installed"

  local team
  fn_pick_team "Pick team to remove" "${names[@]}" || { fn_ui_cancelled; exit 0; }
  team="$UI_RESULT"

  fn_ui_node "Removing $team:"
  fn_ui_lines \
    "  • Remove .claude/commands/$team/" \
    "  • Remove .claude/agents/$team/" \
    "  • Remove .claude/hooks/$team/" \
    "  • Remove .claude/templates/$team/ (if any)" \
    "  • Remove .claude/.fragments/$team.json" \
    "  • Re-merge settings.json" \
    "  • Preserve __ai__/$team/"
  fn_ui_blank

  if ! fn_ui_confirm; then
    fn_ui_cancelled
    exit 0
  fi

  fn_remove_team "$team" "$target"
  # Update record FIRST: remove_team is the commit point; if settings_merge later
  # fails, the team is correctly absent from the record so a retry won't mis-treat it.
  fn_teams_record_remove "$team" "$target"
  fn_settings_merge "$target"

  fn_ui_done
}

# -------------------- main --------------------

# Action labels — defined as constants so the case below stays in sync if these
# labels ever change (i18n, copy edits).
readonly ACTION_INSTALL="Install team"
readonly ACTION_REMOVE="Remove team"

fn_ui_select "What would you like to do?" \
  "$ACTION_INSTALL" \
  "$ACTION_REMOVE" \
  || { fn_ui_cancelled; exit 0; }

case "$UI_RESULT" in
  "$ACTION_INSTALL") fn_flow_install ;;
  "$ACTION_REMOVE")  fn_flow_remove ;;
  *) fn_ui_err "internal: unexpected action" "$UI_RESULT"; exit 2 ;;
esac
