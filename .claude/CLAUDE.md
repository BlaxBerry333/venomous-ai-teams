# 本仓库自身开发规范

每轮固定注入，硬上限 50 行。

## 防幻觉

- 引用文件 / 函数 / 路径前先 Glob / Read / Grep 实证存在
- 改完 `.claude/{agents,commands,hooks}/`、`.claude/settings.json`，或 `teams/*/.claude/{agents,commands,hooks,settings.json}`，或 `setup.sh` 后，宣告「完成」前必须 spawn `审查员` sub-agent，至少 2 个独立实例都零发现才算真完成（可并行）；其他改动跳过
- spawn 审查员时按改动量给核查点（小改 2-3 项、大改 5-6 项）+ 一句「按你的边界跑」；硬约束在审查员 .md 自身（≤8 工具调用 / 2 bug 即停）；禁用「挑剔到底 / 穷举攻击面 / 自己造场景」等放大搜索半径的措辞
- 不准凭印象说"应该没事"

## 改动汇报

完成一组改动后，用此 5 列表格汇报，禁止散文式总结：

| 项 | 改前 | 改后 | 影响方向 | 性价比 |
|---|---|---|---|---|

影响方向：✅ 正向 / ⚠️ 中性 / ❌ 负向。性价比：小 / 中 / 大（不要瞎估精确 token 数）。

## 长期记忆

- 重大决策、踩过的坑写到 `__memo__/YYYYMMDD_简短描述.md`
- frontmatter `status: 进行中` 的 memo 挂账由 SessionStart hook（`.claude/hooks/load-memo.sh`）自动注入，不需主动 ls

## 长对话治理

累计改 ~5 个文件、或感觉注意力被稀释时，主动建议 `/compact` 或开新会话。新会话靠 `__memo__/` + git log 接续。

## Bash 兼容（macOS bash 3.2+）

sed 禁 `\s \d \w` 用 POSIX 类；禁 `mapfile` `readarray` `declare -A` `|&`；`set -euo pipefail` 下 grep 无匹配用 `{ pipeline; } || true` 包住。

## 不废话

直接答，不复述用户问题；不长篇总结代码——diff 会说；单句够就单句。

## Commit 纪律

可以 commit，**禁用 Co-Authored-By: Claude** 等 Claude 署名。message 聚焦 why。
