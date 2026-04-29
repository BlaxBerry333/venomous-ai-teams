#!/usr/bin/env bash
# SessionStart hook: 注入 __memo__/ 中所有 status: 进行中 文件的挂账
# 单一真相源：memo 文件 frontmatter status + ## 本轮挂账 checkbox
set -euo pipefail

memo_dir="${CLAUDE_PROJECT_DIR:-.}/__memo__"
[ -d "$memo_dir" ] || exit 0

active=()
for f in "$memo_dir"/*.md; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue
  # 仅取 frontmatter 块（前两个 --- 之间）的 status 行；先剥 CRLF 再匹配
  memo_status="$({ awk '{sub(/\r$/,"")} /^---$/{c++; next} c==1{print} c>=2{exit}' "$f" | grep -E '^status:' || true; } | head -n1 | sed -e 's/^status:[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ "$memo_status" = "进行中" ] && active+=("$f")
done

[ "${#active[@]}" -eq 0 ] && exit 0

printf '__memo__ 进行中：\n'

for f in "${active[@]}"; do
  rel="__memo__/$(basename "$f")"
  # 抽 ## 本轮挂账 段落到下一个 ## 之前的所有内容（先剥 CRLF）
  pending="$(awk '
    {sub(/\r$/,"")}
    /^## 本轮挂账/ {flag=1; next}
    flag && /^## / {exit}
    flag {print}
  ' "$f")"
  unchecked=""
  [ -n "$pending" ] && unchecked="$(printf '%s\n' "$pending" | grep -E '^- \[ \]' || true)"
  if [ -n "$unchecked" ]; then
    printf '\n%s\n%s\n' "$rel" "$unchecked"
  else
    printf '\n%s（无挂账）\n' "$rel"
  fi
done
