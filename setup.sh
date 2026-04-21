#!/usr/bin/env bash
# setup.sh — 交互式安装单个 team 到目标项目
# 用法: bash setup.sh
# 兼容 bash 3.2+ (macOS 默认)
#
# 设计：按需单装模型。一次选一个 team，框架目录 (.claude/) 和该 team 的工作目录
# (__ai__/{team}/) 被写入目标项目。切换 team 时：重跑 setup.sh 选新 team —— 新 team
# 的 .claude/ 会覆盖旧的（框架大脑换了），但 __ai__/{旧 team}/ 下的历史产出不会被删，
# 与新 team 的 __ai__/{新 team}/ 在同一 __ai__/ 下共存。
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
# 颜色 & 样式
# ============================================================
if [ -t 1 ]; then
  BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
  GREEN='\033[32m'; YELLOW='\033[33m'; CYAN='\033[36m'; RED='\033[31m'; MAGENTA='\033[35m'; WHITE='\033[97m'
  BG_GREEN='\033[42m'; BG_RED='\033[41m'
else
  BOLD="" DIM="" RESET="" GREEN="" YELLOW="" CYAN="" RED="" MAGENTA="" WHITE="" BG_GREEN="" BG_RED=""
fi

die()  { printf "${BG_RED}${WHITE}${BOLD} ERROR ${RESET} ${RED}%s${RESET}\n" "$1" >&2; exit 1; }
info() { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}!${RESET} %s\n" "$1"; }
step() { printf "\n${CYAN}${BOLD}▸ %s${RESET}\n" "$1"; }

# ============================================================
# 标题
# ============================================================
printf "\n"
printf "  ${BOLD}${MAGENTA}Venomous AI Teams${RESET}\n"
printf "\n"

# ============================================================
# 交互式选择（单选）
# ============================================================
printf "  ${BOLD}可用团队${RESET} ${DIM}(一次安装一个；切换 team 请重跑 setup.sh)${RESET}\n\n"

IDX=1
while IFS='|' read -r name desc icon; do
  [ -z "$name" ] && continue
  printf "    ${BOLD}${WHITE}%s)${RESET}  %s  ${BOLD}%s${RESET}\n" "$IDX" "$icon" "$name"
  printf "       ${DIM}%s${RESET}\n" "$desc"
  IDX=$((IDX + 1))
done <<< "$TEAM_DEFS"

printf "\n  ${YELLOW}>${RESET} 请选择 ${DIM}(输入序号 1/2/3 或 team 名)${RESET}: "
read -r SELECTION || die "读取输入失败（EOF？请用交互式终端或完整管道输入 3 行：team, 目标路径, Y）"

case "$SELECTION" in
  1) TEAM="dev-team" ;;
  2) TEAM="design-team" ;;
  3) TEAM="docs-team" ;;
  dev-team|design-team|docs-team) TEAM="$SELECTION" ;;
  *) die "无效选择: $SELECTION" ;;
esac

SRC="$TEAMS_DIR/$TEAM/.claude"
[ -d "$SRC" ] || die "团队源目录不存在: $SRC"

# ============================================================
# 目标目录
# ============================================================
printf "\n  ${YELLOW}>${RESET} 目标项目路径: "
read -r TARGET_DIR || die "读取目标路径失败（EOF？）"
TARGET_DIR=$(echo "$TARGET_DIR" | sed "s|^~|$HOME|")
[ -d "$TARGET_DIR" ] || die "目标目录不存在: $TARGET_DIR"

# 危险路径黑名单：防止 rm -rf 打到关键目录或框架自身
ABS_TARGET=$(cd "$TARGET_DIR" && pwd)
case "$ABS_TARGET" in
  /|/Users|/home|/etc|/var|/usr|/bin|/sbin|/tmp)
    die "禁止安装到系统关键目录: $ABS_TARGET" ;;
esac
[ "$ABS_TARGET" = "$HOME" ] && die "禁止安装到 \$HOME 根: ${ABS_TARGET}（请选具体项目子目录）"
[ "$ABS_TARGET" = "$SCRIPT_DIR" ] && die "禁止安装到框架自身目录: ${ABS_TARGET}（这会删除框架源码）"
case "$ABS_TARGET/" in
  "$SCRIPT_DIR"/*) die "禁止安装到框架子目录: ${ABS_TARGET}（会损坏框架源码）" ;;
esac
TARGET_DIR="$ABS_TARGET"

# ============================================================
# 确认
# ============================================================
printf "\n"
printf "  ${DIM}│${RESET}  团队  ${BOLD}%s${RESET}\n" "$TEAM"
printf "  ${DIM}│${RESET}  目标  ${BOLD}%s${RESET}\n" "$TARGET_DIR"

# 检测是否已装过 team（.claude/.venomous-team 是 setup.sh 安装时写的标记）
EXISTING_TEAM=""
if [ -f "$TARGET_DIR/.claude/.venomous-team" ]; then
  EXISTING_TEAM=$(cat "$TARGET_DIR/.claude/.venomous-team" 2>/dev/null | tr -d '[:space:]')
fi

if [ -n "$EXISTING_TEAM" ] && [ "$EXISTING_TEAM" != "$TEAM" ]; then
  printf "  ${DIM}│${RESET}  ${YELLOW}注意: 检测到目标已安装 ${BOLD}%s${RESET}${YELLOW}，本次安装将${RESET}${BOLD}完全替换${RESET} ${YELLOW}.claude/${RESET}\n" "$EXISTING_TEAM"
  printf "  ${DIM}│${RESET}        ${DIM}__ai__/%s/ 下的历史产出会被保留${RESET}\n" "$EXISTING_TEAM"
fi

printf "\n  ${YELLOW}>${RESET} 确认安装? ${DIM}(Y/n)${RESET}: "
read -r CONFIRM || die "读取确认失败（EOF？）"
case "$CONFIRM" in
  n|N|no|NO) printf "\n  ${DIM}已取消${RESET}\n"; exit 0 ;;
esac

# ============================================================
# 安全检查：.claude/ 存在但非本框架管理的内容不允许覆盖
# ============================================================
# 判断"本框架管理"用 .venomous-team 标记文件**是否存在**（而非内容非空），
# 以防标记被 truncate 成 0 字节时误判。
if [ -d "$TARGET_DIR/.claude" ] && [ ! -f "$TARGET_DIR/.claude/.venomous-team" ]; then
  # 忽略常见系统噪声（.DS_Store 等）和 Claude Code 的用户级文件
  # （settings.local.json 是 Claude Code 自动写的本地权限配置，应当与本框架共存）
  REAL_CONTENT=$(find "$TARGET_DIR/.claude" -mindepth 1 \
                   -not -name '.DS_Store' \
                   -not -name '._*' \
                   -not -name 'Thumbs.db' \
                   -not -name 'settings.local.json' \
                   -print -quit 2>/dev/null || true)
  if [ -n "$REAL_CONTENT" ]; then
    die ".claude/ 已存在且非本框架管理（未找到 .venomous-team 标记）。请先手动清理 $TARGET_DIR/.claude/ 或改选其他目录"
  fi
fi

# ============================================================
# 安装
# ============================================================
step "安装 $TEAM"

# .claude/ 目录：完全替换。删除"任何 team 可能写入过"的所有内容——
# 动态枚举 teams/*/.claude/ 下所有出现过的子目录名与顶层文件名，作为本框架的
# 写入清单（会覆盖 agents/commands/templates/hooks/ 等，以及未来新增的 skills/ 之类）。
# settings.local.json 等用户本地文件不在此清单，自然保留。
if [ -d "$TARGET_DIR/.claude" ]; then
  # 收集所有 team 会写入的顶层名字（用 bash 3.2+ 索引数组，防文件名含空格被 IFS 词分裂）
  FRAMEWORK_ITEMS=()
  for td in "$TEAMS_DIR"/*/.claude; do
    [ -d "$td" ] || continue
    for item in "$td"/* "$td"/.[!.]*; do
      [ -e "$item" ] || continue
      name=$(basename "$item")
      # 去重（线性查询；当前规模 ~7 项，无性能问题）
      seen=0
      for existing in ${FRAMEWORK_ITEMS[@]+"${FRAMEWORK_ITEMS[@]}"}; do
        [ "$existing" = "$name" ] && { seen=1; break; }
      done
      [ "$seen" = "0" ] && FRAMEWORK_ITEMS+=("$name")
    done
  done
  # 加 .venomous-team 标记本身（由 setup 写入，不在 team 源里）
  FRAMEWORK_ITEMS+=(".venomous-team")

  for name in "${FRAMEWORK_ITEMS[@]}"; do
    rm -rf "$TARGET_DIR/.claude/$name"
  done
fi

mkdir -p "$TARGET_DIR/.claude"
cp -R "$SRC/." "$TARGET_DIR/.claude/"
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# 写入标记文件（供下次 setup.sh 切 team 检测 + 其他工具识别）
echo "$TEAM" > "$TARGET_DIR/.claude/.venomous-team"

# 动态列出实际安装的顶层项（不同 team 子目录不同：docs-team 无 agents/templates）
INSTALLED_ITEMS=""
for item in "$SRC"/* "$SRC"/.[!.]*; do
  [ -e "$item" ] || continue
  [ -n "$INSTALLED_ITEMS" ] && INSTALLED_ITEMS="$INSTALLED_ITEMS, "
  INSTALLED_ITEMS="${INSTALLED_ITEMS}$(basename "$item")"
done
info ".claude/ (${INSTALLED_ITEMS:-空})"

# __ai__/{team}/ 工作目录：已存在则保留（用户产出），不存在则从模板复制
if [ -d "$TEAMS_DIR/$TEAM/__ai__/$TEAM" ]; then
  mkdir -p "$TARGET_DIR/__ai__"
  if [ -d "$TARGET_DIR/__ai__/$TEAM" ]; then
    warn "保留已存在的 __ai__/$TEAM/ (用户产出未覆盖)"
  else
    cp -R "$TEAMS_DIR/$TEAM/__ai__/$TEAM" "$TARGET_DIR/__ai__/"
    info "__ai__/$TEAM/ (模板骨架)"
  fi
fi

# ============================================================
# 完成
# ============================================================
printf "\n"
printf "  ${BOLD}${GREEN}安装完成${RESET}\n\n"
printf "  ${DIM}目标${RESET}  %s\n\n" "$TARGET_DIR"
printf "  ${BOLD}可用角色命令${RESET}\n"
for f in "$SRC/commands/"*.md; do
  [ -f "$f" ] || continue
  CMD=$(basename "$f" .md)
  printf "    ${CYAN}/%s${RESET}\n" "$CMD"
done
printf "\n  ${BOLD}开始使用${RESET}\n"
printf "    ${WHITE}cd %s && claude${RESET}\n\n" "$TARGET_DIR"
