#!/usr/bin/env bash
# doc-lint.sh — 文档确定性校验（docs-team）
# 用法: doc-lint.sh <文件或目录>
# 输出: [WARN] / [INFO] 行，exit 0
# 兼容 bash 3.2+（macOS 默认）
# 注意: 本脚本由编程专家命令通过 Bash 调用，不是 Claude PreToolUse hook
set -euo pipefail

TARGET="${1:?用法: doc-lint.sh <文件或目录>}"

# 用临时文件做计数器，避免管道子 shell 中 WARN_COUNT 丢失
WARN_FILE=$(mktemp)
echo 0 > "$WARN_FILE"
trap 'rm -f "$WARN_FILE"' EXIT

warn() {
  echo "[WARN] $1"
  local c; c=$(cat "$WARN_FILE"); echo $((c + 1)) > "$WARN_FILE"
}
info() { echo "[INFO] $1"; }

# 构建文件列表
FILES=""
if [ -d "$TARGET" ]; then
  FILES=$(find "$TARGET" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null || true)
elif [ -f "$TARGET" ]; then
  FILES="$TARGET"
else
  info "doc-lint: 目标 $TARGET 不存在，跳过检查"
  exit 0
fi

[ -n "$FILES" ] || { info "doc-lint: 未找到 .md 文件"; exit 0; }

# ============================================================
# 检查 1: 内部链接是否指向存在的文件
# ============================================================
check_internal_links() {
  local file="$1"
  local file_dir=""
  file_dir=$(dirname "$file")
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # 提取 markdown 链接 [text](path) 中的 path
    # 跳过 http/https 链接和纯锚点链接
    links=$(echo "$line" | grep -oE '\[[^]]*\]\([^)]+\)' | grep -oE '\([^)]+\)' | tr -d '()' || true)

    for link in $links; do
      # 跳过外部链接
      echo "$link" | grep -qE '^https?://' && continue
      # 分离路径和锚点
      local path="" anchor=""
      if echo "$link" | grep -q '#'; then
        path=$(echo "$link" | cut -d'#' -f1)
        anchor=$(echo "$link" | cut -d'#' -f2-)
      else
        path="$link"
      fi

      # 纯锚点（#xxx）→ 对当前文件检查锚点
      if [ -z "$path" ] && [ -n "$anchor" ]; then
        check_anchor "$file" "$anchor" "$file" "$line_num"
        continue
      fi

      [ -z "$path" ] && continue

      # 解析相对路径
      local resolved=""
      if [ "${path#/}" != "$path" ]; then
        # 绝对路径（文档框架根目录），尝试在常见 docs 目录下查找
        for docs_root in "docs" "src/content" "content" "."; do
          local try="${docs_root}${path}"
          # 补充 .md 或 index.md
          if [ -f "$try" ]; then resolved="$try"; break; fi
          if [ -f "${try}.md" ]; then resolved="${try}.md"; break; fi
          if [ -d "$try" ] && [ -f "${try}/index.md" ]; then resolved="${try}/index.md"; break; fi
        done
      else
        # 相对路径
        local try="$file_dir/$path"
        if [ -f "$try" ]; then resolved="$try"
        elif [ -f "${try}.md" ]; then resolved="${try}.md"
        elif [ -d "$try" ] && [ -f "${try}/index.md" ]; then resolved="${try}/index.md"
        fi
      fi

      if [ -z "$resolved" ]; then
        warn "$(basename "$file"):$line_num: 链接目标 \"$path\" 不存在"
        continue
      fi

      # 检查锚点
      if [ -n "$anchor" ] && [ -f "$resolved" ]; then
        check_anchor "$resolved" "$anchor" "$file" "$line_num"
      fi
    done
  done < "$file"
}

# ============================================================
# 检查 2: 锚点是否匹配目标文件中的标题
# ============================================================
check_anchor() {
  local target_file="$1"
  local anchor="$2"
  local source_file="$3"
  local source_line="$4"

  # 从目标文件提取所有标题，转换为锚点格式
  local found=0
  while IFS= read -r heading; do
    # 去掉 # 前缀和前后空格
    local text=""
    text=$(echo "$heading" | sed 's/^#\{1,6\}[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 转换为锚点: 小写 ASCII、空格转连字符、删除 ASCII 标点（保留中文等多字节字符）
    # 注意：BSD sed 不支持 \x80-\xff，所以用"删除已知 ASCII 标点"而非"保留指定范围"
    local generated=""
    generated=$(echo "$text" | \
      tr '[:upper:]' '[:lower:]' | \
      sed 's/ /-/g' | \
      sed 's|[.,:;!?@#$%^&*()+=\[\]{}\\<>/\"'"'"'`~]||g' | \
      sed 's/--*/-/g' | \
      sed 's/^-//;s/-$//')

    if [ "$generated" = "$anchor" ]; then
      found=1; break
    fi

    # 也尝试直接匹配（中文标题在 VitePress 中可能直接用原文）
    local direct=""
    direct=$(echo "$text" | sed 's/ /-/g')
    if [ "$direct" = "$anchor" ]; then
      found=1; break
    fi
  done < <(grep -E '^#{1,6} ' "$target_file" 2>/dev/null || true)

  if [ "$found" = "0" ]; then
    warn "$(basename "$source_file"):$source_line: 锚点 \"#$anchor\" 在 $(basename "$target_file") 中未找到匹配的标题"
  fi
}

# ============================================================
# 检查 3: 代码块语言标注
# ============================================================
check_code_blocks() {
  local file="$1"
  local line_num=0
  local in_code=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    if echo "$line" | grep -qE '^[[:space:]]*```'; then
      if [ "$in_code" = "0" ]; then
        in_code=1
        # 检查 ``` 后是否有语言标注
        local lang=""
        lang=$(echo "$line" | sed 's/^[[:space:]]*```//' | sed 's/[[:space:]].*//')
        if [ -z "$lang" ]; then
          warn "$(basename "$file"):$line_num: 代码块缺少语言标注"
        fi
      else
        in_code=0
      fi
    fi
  done < "$file"
}

# ============================================================
# 检查 4: Sidebar 配置同步（VitePress）
# ============================================================
check_sidebar_sync() {
  # 检测 VitePress sidebar 配置
  local sidebar_dir=""
  for try in \
    "docs/.vitepress/default-theme-configs/sidebar" \
    "docs/.vitepress/sidebar" \
    ".vitepress/sidebar" \
    ".vitepress/default-theme-configs/sidebar"; do
    if [ -d "$try" ]; then sidebar_dir="$try"; break; fi
  done

  if [ -z "$sidebar_dir" ]; then
    # 尝试在 config 文件中找 sidebar
    local config_file=""
    for try in "docs/.vitepress/config.ts" "docs/.vitepress/config.mts" ".vitepress/config.ts"; do
      if [ -f "$try" ]; then config_file="$try"; break; fi
    done
    if [ -z "$config_file" ]; then
      info "sidebar 检查: 未检测到 VitePress sidebar 配置，跳过"
      return 0
    fi
    # config 内联 sidebar 的情况暂不支持解析
    info "sidebar 检查: sidebar 可能内联在 config 文件中，暂不支持解析"
    return 0
  fi

  # 从 sidebar 配置文件中提取引用的文档路径
  local sidebar_paths=""
  sidebar_paths=$(grep -rhE "link:[[:space:]]*['\"]" "$sidebar_dir" 2>/dev/null | \
    grep -oE "['\"][^'\"]+['\"]" | tr -d "'\"\`" | \
    sed 's|^/||' || true)

  [ -n "$sidebar_paths" ] || { info "sidebar 检查: 未从 sidebar 配置中提取到路径"; return 0; }

  # 检查 sidebar 中引用的文件是否存在
  for sp in $sidebar_paths; do
    # 确定 docs 根目录
    local docs_root="docs"
    [ -d "$docs_root" ] || docs_root="."

    local full="${docs_root}/${sp}"
    if [ ! -f "$full" ] && [ ! -f "${full}.md" ] && [ ! -f "${full}/index.md" ]; then
      warn "sidebar: 配置引用 \"$sp\" 但文件不存在"
    fi
  done

  # 反向检查: 本次操作的新文件是否在 sidebar 中
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # 转换为 sidebar 可能使用的路径格式
    local rel=""
    rel=$(echo "$f" | sed "s|^docs/||" | sed 's|\.md$||' | sed 's|/index$||')
    if ! grep -rq "$rel" "$sidebar_dir" 2>/dev/null; then
      warn "$(basename "$f"): 文件不在 sidebar 配置中（如为非导航文件请忽略）"
    fi
  done <<< "$FILES"
}

# ============================================================
# 执行所有检查
# ============================================================
info "doc-lint: 开始校验 $TARGET"

while IFS= read -r file; do
  [ -z "$file" ] && continue
  check_internal_links "$file"
  check_code_blocks "$file"
done <<< "$FILES"

check_sidebar_sync

FINAL_COUNT=$(cat "$WARN_FILE")
echo ""
info "doc-lint: 校验完成，共 $FINAL_COUNT 个警告"
exit 0
