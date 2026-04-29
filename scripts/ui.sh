#!/usr/bin/env bash
# ui.sh — clack-style UI primitives. ALL user-visible output goes through here.
# Source me. Do not execute.

fn_ui_init() {
  if [ -t 1 ]; then
    UI_BOLD=$'\033[1m'
    UI_DIM=$'\033[2m'
    UI_RESET=$'\033[0m'
    UI_GRAY=$'\033[90m'
    UI_CYAN=$'\033[36m'
    UI_GREEN=$'\033[32m'
    UI_YELLOW=$'\033[33m'
    UI_RED=$'\033[31m'
    UI_MAGENTA=$'\033[35m'
  else
    UI_BOLD="" UI_DIM="" UI_RESET="" UI_GRAY="" UI_CYAN="" UI_GREEN="" UI_YELLOW="" UI_RED="" UI_MAGENTA=""
  fi
  UI_SYM_TITLE="◆"
  UI_SYM_NODE="◇"
  UI_SYM_LINE="│"
  UI_SYM_END="└"
  UI_SYM_OK="✓"
  UI_SYM_WARN="▲"
  UI_SYM_ERR="✗"
  UI_SYM_DONE="■"
  UI_SYM_DOT_ON="●"
  UI_SYM_DOT_OFF="○"
  # Output channel for fn_ui_select / fn_ui_input. See those functions for why
  # we use a global instead of $() command substitution.
  UI_RESULT=""
  # Closure flag: 1 means a Done./Cancelled./Aborted. node has already been
  # printed; the EXIT trap in setup.sh checks this to avoid double closure.
  UI_CLOSED=0
}

fn_ui_title() {
  printf "\n  ${UI_MAGENTA}${UI_BOLD}%s${UI_RESET} ${UI_BOLD}%s${UI_RESET}\n" "$UI_SYM_TITLE" "$1"
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE"
}

fn_ui_node() {
  # Prompt role: cyan bold symbol + cyan bold text — "I'm asking you something".
  printf "  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}\n" "$UI_SYM_NODE" "$1"
}

fn_ui_line() {
  # Detail role: gray frame + dim body — supporting info, doesn't compete.
  printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_DIM}%s${UI_RESET}\n" "$UI_SYM_LINE" "$1"
}

fn_ui_lines() {
  local arg
  for arg in "$@"; do
    fn_ui_line "$arg"
  done
}

fn_ui_blank() {
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE"
}

fn_ui_ok() {
  # Status row indented inside the frame, so the left │ column stays unbroken.
  # If the message ends with " (...)", color the parenthetical part green to
  # signal it's a status hint (e.g. "merged 1 fragment(s)", "skeleton").
  local msg="$1" head paren
  case "$msg" in
    *' ('*')')
      head="${msg% (*}"
      paren="${msg##*"$head"}"   # remainder, including leading space + parens
      printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_GREEN}%s${UI_RESET} %s${UI_GREEN}%s${UI_RESET}\n" "$UI_SYM_LINE" "$UI_SYM_OK" "$head" "$paren"
      ;;
    *)
      printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_GREEN}%s${UI_RESET} %s\n" "$UI_SYM_LINE" "$UI_SYM_OK" "$msg"
      ;;
  esac
}

fn_ui_warn() {
  printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_YELLOW}%s${UI_RESET} %s\n" "$UI_SYM_LINE" "$UI_SYM_WARN" "$1"
}

fn_ui_err() {
  # fn_ui_err <title> [detail]
  # Title on the ✗ line in red. Optional detail wraps to a new │ continuation
  # line so the left frame stays unbroken.
  local title="$1" detail="${2:-}"
  printf "  ${UI_RED}%s${UI_RESET}  ${UI_RED}%s${UI_RESET}\n" "$UI_SYM_ERR" "$title" >&2
  if [ -n "$detail" ]; then
    printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_RED}%s${UI_RESET}\n" "$UI_SYM_LINE" "$detail" >&2
  fi
}

fn_ui_done() {
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE"
  printf "  ${UI_GREEN}${UI_BOLD}%s${UI_RESET}  ${UI_BOLD}%s${UI_RESET}\n" "$UI_SYM_DONE" "Done."
  UI_CLOSED=1
}

# Closure node for user-cancelled flow (yellow). Stderr so it's safe to call
# from any context. Marks UI_CLOSED so the EXIT trap won't double-print.
fn_ui_cancelled() {
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2
  printf "  ${UI_YELLOW}${UI_BOLD}%s${UI_RESET}  ${UI_BOLD}%s${UI_RESET}\n" "$UI_SYM_DONE" "Cancelled." >&2
  UI_CLOSED=1
}

# Closure node for abnormal termination (red). Called by setup.sh's EXIT trap
# when the script exits non-zero without an explicit closure already printed.
fn_ui_aborted() {
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2
  printf "  ${UI_RED}${UI_BOLD}%s${UI_RESET}  ${UI_BOLD}%s${UI_RESET}\n" "$UI_SYM_DONE" "Aborted." >&2
  UI_CLOSED=1
}

# fn_ui_select <prompt> <opt1> <opt2> ...
# Renders gum's interactive picker (arrow keys + Enter). On success, writes the
# chosen label to global $UI_RESULT and returns 0. On cancel (ESC/Ctrl-C),
# clears $UI_RESULT and returns 1. Caller pattern:
#   fn_ui_select "..." A B C || { fn_ui_cancelled; exit 0; }
#   chosen="$UI_RESULT"
#
# Why a global instead of $() command substitution: a child-shell `exit 0`
# would only kill the subshell, leaving the parent with an empty value and
# no signal to abort. Returning into a global avoids the subshell entirely.
fn_ui_select() {
  local prompt="$1"; shift
  local choice rc

  # Prompt: cyan bold (matches fn_ui_node) + dim key hint.
  printf "  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_DIM}(↑↓ to navigate  ·  Enter to select  ·  ESC to cancel)${UI_RESET}\n" "$UI_SYM_NODE" "$prompt" >&2

  # gum cursor forced to ANSI 16-color cyan (6) — matches our palette,
  # overrides gum's default pink (256-color 212).
  set +e
  choice=$(gum choose --header "" --no-show-help --cursor "     ▸ " --cursor.foreground=6 "$@")
  rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2
    UI_RESULT=""
    return 1
  fi

  # Echo: gray frame + cyan (non-bold) body — "you answered with this".
  printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_CYAN}%s${UI_RESET}\n" "$UI_SYM_END" "$choice" >&2
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2

  UI_RESULT="$choice"
  return 0
}

# fn_ui_input <prompt> [placeholder] -> writes input (with ~ expansion) to
# global $UI_RESULT, returns 0 on success / 1 on cancel.
fn_ui_input() {
  local prompt="$1" placeholder="${2:-}" raw rc

  printf "  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_DIM}(Enter to submit  ·  ESC to cancel)${UI_RESET}\n" "$UI_SYM_NODE" "$prompt" >&2

  set +e
  raw=$(gum input --header "" --no-show-help --prompt "" --placeholder "$placeholder" --cursor.foreground=6)
  rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2
    UI_RESULT=""
    return 1
  fi

  # ~ expansion (only leading ~). Quote the strip pattern so bash does NOT
  # tilde-expand ~/ at parse time (which would yield ${raw#$HOME/} mismatching).
  case "$raw" in
    "~")    raw="$HOME" ;;
    "~/"*)  raw="$HOME/${raw#"~/"}" ;;
  esac

  printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_CYAN}%s${UI_RESET}\n" "$UI_SYM_END" "$raw" >&2
  printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2

  UI_RESULT="$raw"
  return 0
}

# fn_ui_confirm [prompt] -> exit 0 yes / 1 no.
# Uses gum confirm (Y/N keys + arrow keys). ESC = No.
fn_ui_confirm() {
  local prompt="${1:-Proceed?}" rc

  # Same cyan-bold prompt style as fn_ui_node / fn_ui_select / fn_ui_input.
  printf "  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_CYAN}${UI_BOLD}%s${UI_RESET}  ${UI_DIM}(Y / N  ·  ESC to cancel)${UI_RESET}\n" "$UI_SYM_NODE" "$prompt" >&2

  set +e
  gum confirm "" --affirmative="Yes" --negative="No" --no-show-help >/dev/null 2>&1
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_GRAY}Yes${UI_RESET}\n" "$UI_SYM_END" >&2
    printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2
    return 0
  else
    printf "  ${UI_GRAY}%s${UI_RESET}  ${UI_DIM}No${UI_RESET}\n" "$UI_SYM_END" >&2
    printf "  ${UI_GRAY}%s${UI_RESET}\n" "$UI_SYM_LINE" >&2
    return 1
  fi
}

fn_ui_docs_links() {
  fn_ui_blank
  fn_ui_line "Docs"
  fn_ui_line "  https://github.com/BlaxBerry/venomous-ai-teams/blob/main/README.md"
  fn_ui_line "  https://github.com/BlaxBerry/venomous-ai-teams/blob/main/README.zh.md"
  fn_ui_line "  https://github.com/BlaxBerry/venomous-ai-teams/blob/main/README.ja.md"
  printf "\n"
}
