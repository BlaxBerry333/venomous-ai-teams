# Team 公共规范

[English](./team-spec.md) | 中文 | [日本語](./team-spec.ja.md)

写任何 team 之前必须遵守。所有 team 共用此规范。(源自 2026-04-29 定稿的内部规范 v1,自此文件起以 git 内版本为准。)

## 1. 目录结构(`teams/<team>/` 1:1 映射安装产物)

```
teams/<team>/
├── README.md                       # team 说明(4 段:定位/命令/工作流/删除)
├── .claude/                        # → 安装到目标项目 .claude/
│   ├── commands/<team>/*.md        # slash command,文件名中文
│   ├── agents/<team>/*.md          # sub-agent,文件名英文 kebab-case
│   ├── hooks/<team>/*.sh           # 确定性校验脚本
│   ├── .fragments/<team>.json      # settings.json 片段(合成源)
│   └── templates/<team>/*          # 可选:team 模板
└── __ai__/<team>/                  # → 安装到目标项目 __ai__/<team>/
```

删 team = `rm -rf .claude/{commands,agents,hooks,templates}/<team>/ .claude/.fragments/<team>.json __ai__/<team>/`(推荐用 `setup.sh` 的 Remove,会同步重合成 settings.json)

## 2. 命名规范

| 对象 | 规则 | 例 |
|---|---|---|
| slash command 文件名 | 中文,简短 | `设计.md` → `/web-dev-team:设计` |
| slash command team 入口 | `commands/<team>.md` 触发 `/<team>`(可选)| `commands/web-dev-team.md` → `/web-dev-team` |
| sub-agent 文件名 | 中文或英文 kebab-case 均可 | `审查员-逻辑审查.md` 或 `code-reviewer.md` |
| sub-agent frontmatter `name` | **必须英文** `<team>-<role>`(spawn 用) | `web-dev-team-reviewer-logic` |
| hook 脚本 | 英文 kebab-case,`.sh` | `path-guard.sh` |
| team 名 | 英文 kebab-case,`-team` 后缀 | `web-dev-team` |
| 产物目录 | `__ai__/<team>/` | `__ai__/web-dev-team/specs/` |

## 3. settings.json 片段格式(`.fragments/<team>.json`)

```jsonc
{
  "hooks": { ... },
  "permissions": { "allow": [...], "deny": [...] }
}
```

- 仅允许 `hooks` + `permissions`;禁写 `env / theme / model` 等全局项
- 由 `scripts/settings.sh` 用 jq 合成进目标项目 settings.json(多 team 片段并列合并;这两个字段视为框架管理,用户个人配置放 settings.local.json)

## 4. hook 契约

- `#!/usr/bin/env bash` + `set -euo pipefail`
- 兼容 macOS bash 3.2+(禁 mapfile / declare -A / `\s\d\w`)
- exit(Claude Code 官方语义,与 Unix 惯例**相反**):`0` 通过 / **`2` 阻断**(stderr 反馈给 LLM)/ **`1` 不阻断**(stderr 首行作为 hook error notice 显示)
- stderr = 用户/LLM 看;stdout 仅在 exit 0 时被解析为 JSON 控制结构
- 路径用 `${CLAUDE_PROJECT_DIR}`,不用相对路径
- 只读 `__ai__/<team>/` 和当前改动文件;**禁跨 team 读** `__ai__/<他 team>/`

## 5. sub-agent prompt 契约

- ≤ 60 行
- frontmatter 必含:`name` / `description` / `tools` / `model`
- `description` 写**触发条件**(给 hook / 主对话判断用),非介绍
- `tools` 最小集合,禁全开
- Bash 用最严 deny(rm / sudo / curl POST 等)

## 6. slash command 契约

- ≤ 80 行
- frontmatter:`description` 一句话;`argument-hint` 必填
- 主体 imperative 直给步骤,禁开场白
- 引用 team 资源用项目根相对路径 `.claude/agents/<team>/xxx.md`(不带前导 `/`)

## 7. 产物路径(`__ai__/<team>/`)

- team 自定义子结构,**禁写到 team 目录外**
- specs/decisions 强制 `YYYYMMDD_xxx.md` 前缀
- 临时草稿放 `__ai__/<team>/.scratch/`,setup.sh 不复制

## 8. README.md(每 team 必备)

固定四段:定位(1 句)/ 装后新增命令 / 典型工作流(≤5 步)/ 删除方式。中英日三语言版本(README.md 英文为默认)。

## 量化目标

- sub-agent prompt ≤ 60 行
- 顶层 CLAUDE.md ≤ 50 行(每轮固定注入)
- 简单需求(改 1-2 文件)零 sub-agent 调用
