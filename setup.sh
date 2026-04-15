#!/usr/bin/env bash
# setup.sh — 交互式安装一个或多个 team 到目标项目
# 用法: bash setup.sh
# 兼容 bash 3.2+ (macOS 默认)
set -euo pipefail

# ============================================================
# 常量
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEAMS_DIR="$SCRIPT_DIR/teams"

# 团队定义: 名称|描述|图标
TEAM_DEFS="dev-team|5 角色开发流程 (设计 → 验证 → 开发 → 审查 → 测试)|🔨
design-team|4 角色设计流程 (设计规格 → 验证 → HTML+CSS 原型 → 设计审查)|🎨
docs-team|领域专家驱动的知识库文档工作流|📝"

# ============================================================
# 颜色 & 样式 (ANSI escape, 终端不支持时自动降级)
# ============================================================
if [ -t 1 ]; then
  BOLD='\033[1m'
  DIM='\033[2m'
  RESET='\033[0m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  CYAN='\033[36m'
  RED='\033[31m'
  MAGENTA='\033[35m'
  WHITE='\033[97m'
  BG_GREEN='\033[42m'
  BG_RED='\033[41m'
else
  BOLD="" DIM="" RESET="" GREEN="" YELLOW="" CYAN="" RED="" MAGENTA="" WHITE="" BG_GREEN="" BG_RED=""
fi

# ============================================================
# 辅助函数
# ============================================================
die()     { printf "${BG_RED}${WHITE}${BOLD} ERROR ${RESET} ${RED}%s${RESET}\n" "$1" >&2; exit 1; }
info()    { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
step()    { printf "\n${CYAN}${BOLD}▸ %s${RESET}\n" "$1"; }
confirm() { printf "${BG_GREEN}${WHITE}${BOLD} DONE ${RESET} ${GREEN}%s${RESET}\n" "$1"; }

# ============================================================
# 标题
# ============================================================
printf "\n"
printf "  ${BOLD}${MAGENTA}Venomous AI Teams${RESET}\n"
printf "\n"

# ============================================================
# 交互式选择
# ============================================================
printf "  ${BOLD}可用团队:${RESET}\n\n"

IDX=1
TEAM_NAMES=""
while IFS='|' read -r name desc icon; do
  [ -z "$name" ] && continue
  printf "    ${BOLD}${WHITE}%s)${RESET}  %s  ${BOLD}%s${RESET}\n" "$IDX" "$icon" "$name"
  printf "       ${DIM}%s${RESET}\n" "$desc"
  TEAM_NAMES="$TEAM_NAMES $name"
  IDX=$((IDX + 1))
done <<< "$TEAM_DEFS"
TEAM_NAMES="${TEAM_NAMES# }"

printf "\n    ${BOLD}${WHITE}a)${RESET}  ⭐  ${BOLD}全部安装${RESET}\n"
printf "\n"
printf "  ${YELLOW}>${RESET} 请选择 ${DIM}(空格/逗号分隔, 如 ${RESET}1 2${DIM} 或 ${RESET}1,3${DIM} 或 ${RESET}a${DIM})${RESET}: "
read -r SELECTION

# 解析选择
SELECTED_TEAMS=""
if [ "$SELECTION" = "a" ] || [ "$SELECTION" = "A" ]; then
  SELECTED_TEAMS="$TEAM_NAMES"
else
  SELECTION=$(echo "$SELECTION" | tr ',' ' ')
  for sel in $SELECTION; do
    case "$sel" in
      1) SELECTED_TEAMS="$SELECTED_TEAMS dev-team" ;;
      2) SELECTED_TEAMS="$SELECTED_TEAMS design-team" ;;
      3) SELECTED_TEAMS="$SELECTED_TEAMS docs-team" ;;
      dev-team|design-team|docs-team) SELECTED_TEAMS="$SELECTED_TEAMS $sel" ;;
      *) die "无效选择: $sel" ;;
    esac
  done
fi
SELECTED_TEAMS="${SELECTED_TEAMS# }"
[ -n "$SELECTED_TEAMS" ] || die "未选择任何团队"

# 去重
TEAMS=""
for t in $SELECTED_TEAMS; do
  case " $TEAMS " in
    *" $t "*) ;;
    *) TEAMS="$TEAMS $t" ;;
  esac
done
TEAMS="${TEAMS# }"

TEAM_COUNT=0
for t in $TEAMS; do TEAM_COUNT=$((TEAM_COUNT + 1)); done

printf "\n  ${GREEN}已选择:${RESET} ${BOLD}%s${RESET}\n\n" "$TEAMS"

# 目标目录
printf "  ${YELLOW}>${RESET} 目标项目路径: "
read -r TARGET_DIR

# 展开 ~ 为 HOME（read 不自动展开 tilde）
TARGET_DIR=$(echo "$TARGET_DIR" | sed "s|^~|$HOME|")

[ -d "$TARGET_DIR" ] || die "目标目录不存在: $TARGET_DIR"

# 确认
printf "\n"
printf "  ${DIM}│${RESET}  团队  ${BOLD}%s${RESET}\n" "$TEAMS"
printf "  ${DIM}│${RESET}  目标  ${BOLD}%s${RESET}\n" "$TARGET_DIR"
printf "\n"
printf "  ${YELLOW}>${RESET} 确认安装? ${DIM}(Y/n)${RESET}: "
read -r CONFIRM
case "$CONFIRM" in
  n|N|no|NO) printf "\n  ${DIM}已取消${RESET}\n"; exit 0 ;;
esac

# ============================================================
# 第一步: 创建目标 .claude 目录结构
# ============================================================
step "复制团队文件"

mkdir -p "$TARGET_DIR/.claude/hooks"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/commands"
mkdir -p "$TARGET_DIR/.claude/templates"

# ============================================================
# 第二步: 复制不冲突的文件 (agents/ commands/ templates/)
# ============================================================
for team in $TEAMS; do
  SRC="$TEAMS_DIR/$team/.claude"

  if [ -d "$SRC/agents" ]; then
    cp "$SRC/agents/"*.md "$TARGET_DIR/.claude/agents/" 2>/dev/null || true
  fi

  if [ -d "$SRC/commands" ]; then
    cp "$SRC/commands/"*.md "$TARGET_DIR/.claude/commands/" 2>/dev/null || true
  fi

  if [ -d "$SRC/templates" ]; then
    for f in "$SRC/templates/"*; do
      [ -f "$f" ] || continue
      cp "$f" "$TARGET_DIR/.claude/templates/"
    done
  fi

  if [ -d "$TEAMS_DIR/$team/__ai__" ]; then
    mkdir -p "$TARGET_DIR/__ai__"
    if [ -d "$TEAMS_DIR/$team/__ai__/$team" ]; then
      cp -r "$TEAMS_DIR/$team/__ai__/$team" "$TARGET_DIR/__ai__/"
    fi
  fi

  info "$team"
done

# ============================================================
# 第三步: 合并 hooks/
# ============================================================
step "合并 hooks"

# --- 3a: role-guard.sh ---
RG_TEAMS=""
for team in $TEAMS; do
  [ -f "$TEAMS_DIR/$team/.claude/hooks/role-guard.sh" ] && RG_TEAMS="$RG_TEAMS $team"
done
RG_TEAMS="${RG_TEAMS# }"

RG_COUNT=0
for t in $RG_TEAMS; do RG_COUNT=$((RG_COUNT + 1)); done

if [ "$RG_COUNT" = "0" ]; then
  :
elif [ "$RG_COUNT" = "1" ]; then
  for t in $RG_TEAMS; do
    cp "$TEAMS_DIR/$t/.claude/hooks/role-guard.sh" "$TARGET_DIR/.claude/hooks/role-guard.sh"
  done
  info "role-guard.sh ${DIM}← ${RG_TEAMS}${RESET}"
else
  FIRST_RG_TEAM=""
  for t in $RG_TEAMS; do
    [ -z "$FIRST_RG_TEAM" ] && FIRST_RG_TEAM="$t"
  done

  ALL_CASES=""
  for team in $RG_TEAMS; do
    SRC="$TEAMS_DIR/$team/.claude/hooks/role-guard.sh"
    CASES=$(sed -n '/^get_rules()/,/^}/p' "$SRC" | grep -E '^[[:space:]]+"' || true)
    ALL_CASES="$ALL_CASES
$CASES"
  done

  SKELETON="$TEAMS_DIR/$FIRST_RG_TEAM/.claude/hooks/role-guard.sh"
  BEFORE=$(sed -n '1,/^get_rules()/p' "$SKELETON" | sed '$d')
  GR_END=$(grep -n '^}' "$SKELETON" | head -1 | cut -d: -f1)
  TOTAL=$(wc -l < "$SKELETON" | tr -d ' ')
  AFTER=$(tail -n $((TOTAL - GR_END)) "$SKELETON")

  UNIQUE_CASES=$(echo "$ALL_CASES" | grep -E '^[[:space:]]+"' | sort -u)

  {
    echo "$BEFORE"
    echo 'get_rules() {'
    echo '  case "$1" in'
    echo "$UNIQUE_CASES"
    echo '    *)              return 1 ;;'
    echo '  esac'
    echo '}'
    echo "$AFTER"
  } > "$TARGET_DIR/.claude/hooks/role-guard.sh"
  chmod +x "$TARGET_DIR/.claude/hooks/role-guard.sh"

  info "role-guard.sh ${DIM}← merged: ${RG_TEAMS}${RESET}"
fi

# --- 3b: doc-lint.sh ---
DL_TEAMS=""
for team in $TEAMS; do
  [ -f "$TEAMS_DIR/$team/.claude/hooks/doc-lint.sh" ] && DL_TEAMS="$DL_TEAMS $team"
done
DL_TEAMS="${DL_TEAMS# }"

DL_COUNT=0
for t in $DL_TEAMS; do DL_COUNT=$((DL_COUNT + 1)); done

if [ "$DL_COUNT" = "0" ]; then
  :
elif [ "$DL_COUNT" = "1" ]; then
  for t in $DL_TEAMS; do
    cp "$TEAMS_DIR/$t/.claude/hooks/doc-lint.sh" "$TARGET_DIR/.claude/hooks/doc-lint.sh"
  done
  info "doc-lint.sh ${DIM}← ${DL_TEAMS}${RESET}"
else
  for team in $DL_TEAMS; do
    cp "$TEAMS_DIR/$team/.claude/hooks/doc-lint.sh" \
       "$TARGET_DIR/.claude/hooks/doc-lint-${team}.sh"
    chmod +x "$TARGET_DIR/.claude/hooks/doc-lint-${team}.sh"
  done

  cat > "$TARGET_DIR/.claude/hooks/doc-lint.sh" <<'DISPATCHER'
#!/usr/bin/env bash
# doc-lint.sh — 自动分发器 (由 setup.sh 生成)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARG="${1:-}"

if echo "$ARG" | grep -q '__ai__/dev-team'; then
  exec "$SCRIPT_DIR/doc-lint-dev-team.sh" "$@"
elif [ -f "$SCRIPT_DIR/doc-lint-docs-team.sh" ]; then
  exec "$SCRIPT_DIR/doc-lint-docs-team.sh" "$@"
elif [ -f "$SCRIPT_DIR/doc-lint-dev-team.sh" ]; then
  exec "$SCRIPT_DIR/doc-lint-dev-team.sh" "$@"
else
  echo "[ERROR] doc-lint: 未找到任何 team 的 doc-lint 实现" >&2
  exit 1
fi
DISPATCHER
  chmod +x "$TARGET_DIR/.claude/hooks/doc-lint.sh"

  info "doc-lint.sh ${DIM}← dispatcher: ${DL_TEAMS}${RESET}"
fi

# --- 3c: path-guard.sh (Command 注入模型 teams 使用) ---
PG_TEAMS=""
for team in $TEAMS; do
  [ -f "$TEAMS_DIR/$team/.claude/hooks/path-guard.sh" ] && PG_TEAMS="$PG_TEAMS $team"
done
PG_TEAMS="${PG_TEAMS# }"

PG_COUNT=0
for t in $PG_TEAMS; do PG_COUNT=$((PG_COUNT + 1)); done

if [ "$PG_COUNT" = "0" ]; then
  :
elif [ "$PG_COUNT" = "1" ]; then
  for t in $PG_TEAMS; do
    cp "$TEAMS_DIR/$t/.claude/hooks/path-guard.sh" "$TARGET_DIR/.claude/hooks/path-guard.sh"
  done
  chmod +x "$TARGET_DIR/.claude/hooks/path-guard.sh"
  info "path-guard.sh ${DIM}← ${PG_TEAMS}${RESET}"
else
  # 多团队 path-guard 合并（目前仅 docs-team 一个 Command 注入 team，暂用第一个）
  FIRST_PG_TEAM=""
  for t in $PG_TEAMS; do
    [ -z "$FIRST_PG_TEAM" ] && FIRST_PG_TEAM="$t"
  done
  cp "$TEAMS_DIR/$FIRST_PG_TEAM/.claude/hooks/path-guard.sh" "$TARGET_DIR/.claude/hooks/path-guard.sh"
  chmod +x "$TARGET_DIR/.claude/hooks/path-guard.sh"
  info "path-guard.sh ${DIM}← ${FIRST_PG_TEAM}${RESET} (多团队合并暂用第一个)"
fi

# --- 3d: 复制不冲突的 hooks ---
for team in $TEAMS; do
  SRC="$TEAMS_DIR/$team/.claude/hooks"
  [ -d "$SRC" ] || continue
  for f in "$SRC/"*; do
    [ -f "$f" ] || continue
    FNAME=$(basename "$f")
    case "$FNAME" in
      role-guard.sh|doc-lint.sh|path-guard.sh) continue ;;
    esac
    cp "$f" "$TARGET_DIR/.claude/hooks/$FNAME"
    info "$FNAME ${DIM}← ${team}${RESET}"
  done
done

chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# ============================================================
# 第四步: 合并 settings.json
# ============================================================
step "生成配置"

ALL_DENY_FILE=$(mktemp)
for team in $TEAMS; do
  SRC="$TEAMS_DIR/$team/.claude/settings.json"
  [ -f "$SRC" ] || continue
  grep -oE '"Bash\([^"]*\)"' "$SRC" >> "$ALL_DENY_FILE" 2>/dev/null || true
done
DENY_UNIQUE_FILE=$(mktemp)
sort -u "$ALL_DENY_FILE" > "$DENY_UNIQUE_FILE"
rm -f "$ALL_DENY_FILE"

NEED_HOOK=0
[ -n "${RG_TEAMS:-}" ] && NEED_HOOK=1
[ -n "${PG_TEAMS:-}" ] && NEED_HOOK=1

# 构造 hooks 数组（可能同时包含 role-guard 和 path-guard）
HOOK_ENTRIES=""
[ -n "${RG_TEAMS:-}" ] && HOOK_ENTRIES="$HOOK_ENTRIES role-guard"
[ -n "${PG_TEAMS:-}" ] && HOOK_ENTRIES="$HOOK_ENTRIES path-guard"
HOOK_ENTRIES="${HOOK_ENTRIES# }"

{
  echo '{'
  echo '  "permissions": {'
  echo '    "defaultMode": "acceptEdits",'
  echo '    "allow": ["Bash", "Edit", "Write"],'
  echo -n '    "deny": ['

  FIRST=1
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    if [ "$FIRST" = "1" ]; then
      echo ""
      FIRST=0
    else
      echo ","
    fi
    echo -n "      $item"
  done < "$DENY_UNIQUE_FILE"
  rm -f "$DENY_UNIQUE_FILE"
  echo ""
  echo '    ]'

  if [ "$NEED_HOOK" = "1" ]; then
    echo '  },'
    echo '  "hooks": {'
    echo '    "PreToolUse": ['
    echo '      {'
    echo '        "matcher": "Edit|Write",'
    echo -n '        "hooks": ['
    HFIRST=1
    for h in $HOOK_ENTRIES; do
      if [ "$HFIRST" = "1" ]; then HFIRST=0; else echo -n ", "; fi
      echo -n "{\"type\": \"command\", \"command\": \".claude/hooks/${h}.sh\"}"
    done
    echo ']'
    echo '      }'
    echo '    ]'
    echo '  }'
  else
    echo '  }'
  fi

  echo '}'
} > "$TARGET_DIR/.claude/settings.json"

info "settings.json"

# ============================================================
# 第五步: 合并 CLAUDE.md
# ============================================================
TEAM_LIST=""
for team in $TEAMS; do
  [ -n "$TEAM_LIST" ] && TEAM_LIST="$TEAM_LIST + "
  TEAM_LIST="$TEAM_LIST$team"
done

HAS_SUBAGENT=0
HAS_COMMAND=0
for team in $TEAMS; do
  case "$team" in
    dev-team|design-team) HAS_SUBAGENT=1 ;;
    docs-team)            HAS_COMMAND=1 ;;
  esac
done

{
  echo "# AI 多团队协作系统"
  echo ""
  echo "已安装团队: $TEAM_LIST"
  echo ""

  if [ "$HAS_SUBAGENT" = "1" ] && [ "$HAS_COMMAND" = "1" ]; then
    echo "本项目包含两种执行模型的团队："
    echo "- **SubAgent 隔离模型** (角色运行在独立子进程，通过文件通信)"
    echo "- **Command 注入模型** (角色直接在主对话中执行，上下文持续)"
    echo ""
  fi

  if [ "$HAS_SUBAGENT" = "1" ]; then
    echo "SubAgent 团队共享以下机制："
    echo "- 角色间仅通过 \`__ai__/\` 目录下的文件通信"
    echo "- 权限通过 PreToolUse hook 自动拦截越权操作"
    echo "- 调度器在 agent 返回后执行 git diff 事后验证"
    echo ""
  fi

  if [ "$TEAM_COUNT" -gt 1 ]; then
    echo "## 跨团队保护"
    echo ""
    echo "- 各团队的 \`__ai__/{team}/\` 输出目录互相隔离，不得跨团队修改"
    echo "- 角色只能修改自己团队的文件 (由 role-guard.sh 强制)"
    echo ""
  fi

  for team in $TEAMS; do
    SRC="$TEAMS_DIR/$team/.claude/CLAUDE.md"
    [ -f "$SRC" ] || continue

    START_PAT="<!-- VENOMOUS:${team}:START -->"
    END_PAT="<!-- VENOMOUS:${team}:END -->"

    if grep -q "$START_PAT" "$SRC"; then
      sed -n "/$START_PAT/,/$END_PAT/p" "$SRC"
    else
      echo "<!-- VENOMOUS:${team}:START -->"
      cat "$SRC"
      echo "<!-- VENOMOUS:${team}:END -->"
    fi
    echo ""
  done

} > "$TARGET_DIR/.claude/CLAUDE.md"

info "CLAUDE.md"

# ============================================================
# 完成
# ============================================================
printf "\n"
printf "  ${BOLD}${GREEN}安装完成!${RESET}\n"
printf "\n"
printf "  ${DIM}目标${RESET}  %s\n" "$TARGET_DIR"
printf "\n"
printf "  ${BOLD}可用角色命令:${RESET}\n"
for team in $TEAMS; do
  SRC="$TEAMS_DIR/$team/.claude/commands"
  [ -d "$SRC" ] || continue
  for f in "$SRC/"*.md; do
    [ -f "$f" ] || continue
    CMD=$(basename "$f" .md)
    printf "    ${CYAN}/%s${RESET}  ${DIM}%s${RESET}\n" "$CMD" "$team"
  done
done
printf "\n"
printf "  ${BOLD}开始使用:${RESET}\n"
printf "    ${WHITE}cd %s && claude${RESET}\n" "$TARGET_DIR"
printf "\n"
