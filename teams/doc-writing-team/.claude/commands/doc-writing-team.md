---
description: doc-writing-team 全流程：判定目录形态 → collector 抓素材 → 用户确认大纲 → writer 写。中等以上文档任务一键发起
argument-hint: <文档主题/意图，可含 URL>
---

你是 doc-writing-team 全流程调度。按下方剧本顺序执行，不跳步。

## 第 0 步：分流

判断 `$ARGUMENTS`：
- 仅翻译既有文件 → 回："翻译请用 `/doc-writing-team:翻译 <翻译需求>`（如 `把 docs/intro.md 翻成英文`）"，**结束**
- 主题过虚（"写点东西" / "随便写"，无具体题目/对象）→ 反问 1-3 个具体问题，**硬断点等用户回**，禁继续
- 当前会话已有 doc-writing-team 产物 + 用户语义 "再加 / 删了 / 改成 / 太废话 / 重写" → 走「追加/调整流程」段
- 其他 → 进第 1 步

## 第 1 步：生成 slug + 判定目录形态

主对话先按 `$ARGUMENTS` 主题生成 `slug=<kebab-case>`（如 "trpc 入门" → `trpc-getting-started`），后续第 3 步 collector / 第 5 步 writer 全程复用此值，不允许 sub-agent 重新推断。

然后按以下顺序实证目录形态（命中即停）：
1. `Bash: ls mkdocs.yml mkdocs.yaml docusaurus.config.js docusaurus.config.ts docusaurus.config.mjs 2>/dev/null` 或 `Bash: find . -maxdepth 3 -path '*/.vitepress/config.*' -print -quit` 命中 → **docs-project**（框架按命中文件名定：vitepress / docusaurus / mkdocs）
2. `Bash: cat package.json 2>/dev/null | grep -E '"(vitepress|@docusaurus/core|@astrojs/starlight)"'` 命中 → **docs-project**，框架按依赖名定
3. `docs/` 目录存在且**未被 .gitignore 忽略**（`Bash: test -d docs && ! grep -qE '^/?docs/?$' .gitignore 2>/dev/null && echo Y`）→ **pure-docs**（落 `docs/`；被 gitignore 通常是 typedoc/jsdoc 等自动生成目录，跳过）
4. 顶层无 `package.json`（`Bash: test -f package.json && echo Y || echo N` 输出 `N`）+ `Glob: *.md` 命中 ≥ 1 → **pure-docs**（纯 markdown 仓库）
5. 其他（普通代码仓 / 空目录 / 文档相关均无）→ **scratch**（项目根新建 `docs/`，落到 `docs/<slug>/`）

向用户**单行播报**判定结果，不等确认（自动判断硬规）。

## 第 2 步：多语言询问

播报："**需要多语言版本吗？默认中文单一版本。** 回复语言列表（如 `zh,en,ja`）或 `不要`。"
**硬断点等用户回**。沉默 / "不要" → `lang=["zh"]`。

## 第 3 步：collector

一次消息 spawn `doc-writing-team-collector`，传：主题 + URL（从 `$ARGUMENTS` 提取）+ slug。

收到 collector 汇报后**硬断点**："素材够吗？回复 `够` / `补 <主题>` / `算了`"
- `够` → 进第 4 步
- `补 X` → 再 spawn collector 增量抓 X
- `算了` → 流程停

## 第 4 步：大纲

主对话直接做（不 spawn）：Read 全部 sources → 输出**目录大纲 + 各章节 1-2 句要点**（形态/落地路径/`index.md — 要点` + `ch1-<slug>.md — 要点`...）。

播报："大纲 OK 吗？回复 `OK` / `改 <说明>` / `算了`"。**硬断点等用户**。

## 第 5 步：writer

一次消息 spawn `doc-writing-team-writer`，传齐 7 字段（与 writer.md input 段对齐）：**意图**（用户原始 `$ARGUMENTS`）+ **slug**（第 1 步主对话生成的同一 slug）+ sources 路径列表 + 落地形态 + 框架 + 多语言列表 + 大纲。

## 第 6 步：最终总结

writer 汇报"素材为零无法成文" → 跳过本步，直接输出"═══ doc-writing-team 中止 ═══ 素材不足以成文，sources 目录在 `__ai__/doc-writing-team/sources/`（可能已有 partial 内容），请人工检查后用 `/doc-writing-team` 补抓或手动补 sources 文件后重试"，**不输出 compact 提示**（用户需先排查问题，compact 后丢失诊断上下文反而坏事）。

否则正常输出："═══ doc-writing-team 完成 ═══" + 新增/改动文件列表 + sources 目录 + 未填 TODO（零项写"无"）+ 末尾**单条** compact 提示：

- 默认（sources ≤ 20k tokens）：`本轮已落盘（正文 docs/，素材 __ai__/doc-writing-team/sources/），建议 /compact 后再继续；追加（"再加 X / 删了 Y / 改成 Z"）也建议 compact 后说，下次会话 Read 上述路径即可接续`
- sources > 20k tokens：替换为 `⚠️ 已积累 ~Nk tokens 素材上下文，**强烈建议**先 /compact，下次会话 Read docs/ 与 __ai__/doc-writing-team/sources/ 接续`

token 估算：`Bash: du -sk __ai__/doc-writing-team/sources 2>/dev/null` 拿 KB → tokens ≈ KB × 0.4（中文 1KB≈350 token，英文 1KB≈250 token，混合取 0.4 偏稳）。两段提示**互斥替换**，禁同时输出。

## 追加/调整流程（识别为追加时走这段）

播报："识别为追加/调整，主对话内直接处理，不重跑、不开 task"。然后按情形：
- 调整（改文风/删段/重写）→ 主对话 Edit，禁 spawn writer
- 加章节 + sources 够 → 主对话写新章节 + 更新 index/sidebar
- 加章节 + sources 不够 → spawn collector 增量抓 → 主对话写
- 体量爆炸（>5 文件 / 主题完全跑题）→ 建议 `/doc-writing-team <新主题>` 开独立 task

追加每轮结束时末尾追加一句：`本轮追加已落盘，连续追加 ≥ 3 轮或感觉对话变长时，/compact 后开新会话续聊，sources 仍在 __ai__/doc-writing-team/sources/`。

## 用户需求

$ARGUMENTS
