# doc-writing-team

中文 | [English](./README.en.md) | [日本語](./README.ja.md)

## 是什么

逼 Claude 在文档任务上**先有据再下笔**：collector 抓素材落 sources/、writer 工具白名单不含联网、用户拍板大纲后才动笔。**只产 .md/.mdx**，不写代码、不跑 build。

## 工作流 + 特点

`/doc-writing-team <主题>` → 自动判定目录形态 → 询问多语言 → collector 抓素材 → 你确认素材 → 出大纲 → 你确认大纲 → writer 写。

- **来源可追溯**：每条事实落 `sources/` 带 URL + 抓取时间；writer 工具白名单不含 WebFetch/WebSearch 杜绝边写边编
- **目录形态自适应**：自动识别纯文档仓 / VitePress·Docusaurus·MkDocs 项目 / 普通仓三种形态
- **大纲先确认再写**：复杂主题先输出嵌套结构 + 各章节要点，你拍板才动笔
- **追加调整不开 task**：本对话内说"再加 X / 删了 Y / 改成 Z"主对话直接改
- **多语言询问态**：默认中文单一版本，任务开始问一次

## 角色

| 角色 | 干啥 | 不干啥 |
|---|---|---|
| **collector** | 抓 + 摘 + 落 sources/ | 不写最终文档、不脑补、不跨主题混合 |
| **writer** | 按确认大纲写最终文档 + 更新 sidebar/nav | 不联网、不写代码、不装依赖、不跑 build |

## 对比第三方（数据 2026-05）

| 维度 | doc-writing-team | Mintlify | Docusaurus | 直接 ChatGPT/Claude |
|---|:---:|:---:|:---:|:---:|
| 来源可追溯<br/>（frontmatter sources[]） | ✅ | ❌ | ❌ | ❌ |
| 物理反幻觉<br/>（writer 工具无联网） | ✅ | ❌<br/>Writing Agent 可联网 | N/A | ❌ |
| 大纲确认硬断点 | ✅ | ❌<br/>直接生成 | N/A | ⚠️<br/>看用户主动 |
| 多语言 i18n 自适应 | ✅<br/>Glob 观察 | ✅<br/>docs.json | ✅<br/>i18n/ | ❌ |
| 翻译保结构<br/>（mdx/frontmatter/代码块） | ✅<br/>1:1 硬规 | ⚠️<br/>需手动<br/>或接 Locadex | ⚠️<br/>需手动<br/>或接 Crowdin | ❌ |
| 平台 | Claude Code | SaaS | OSS | 网页/API |
| 单次中等需求成本 | $0.30-1.20 | $250/月起 | 免费 + 自带 LLM | $0.05-0.20 |

## 使用

### 安装/删除

```bash
bash setup.sh   # 交互式选 install / remove + team + 目标项目
```

### 命令

| 命令 | 干啥 |
|---|---|
| `/doc-writing-team <主题>` | 全流程<br/>形态判定 → 多语言询问 → collector → 用户确认素材 → 大纲 → 用户确认大纲 → writer |
| `/doc-writing-team:翻译 <翻译需求>` | 单文件 / Glob 批量翻译<br/>如 `把 docs/intro.md 翻成英文`，保结构不重写 |

### 装后目录结构（你的项目里）

```
<你的项目>/
├── .claude/
│   ├── commands/
│   │   ├── doc-writing-team.md            # /doc-writing-team 入口（全流程调度）
│   │   └── doc-writing-team/
│   │       └── 翻译.md                    # /doc-writing-team:翻译
│   ├── agents/doc-writing-team/
│   │   ├── collector.md                   # name: doc-writing-team-collector
│   │   └── writer.md                      # name: doc-writing-team-writer
│   ├── hooks/doc-writing-team/
│   │   └── path-guard.sh                  # 阻断 sub-agent 写入 .claude/
│   ├── templates/doc-writing-team/
│   │   ├── source-template.md             # collector 用
│   │   └── article-template.md            # writer 用
│   └── .fragments/doc-writing-team.json   # hook + permissions 片段（合成进 settings.json）
│
├── __ai__/
│   └── doc-writing-team/                  # collector 抓的素材（删除 team 时保留）
│       └── sources/
│           └── YYYYMMDD_<slug>__N.md
│
└── docs/                                  # writer 落地（所有形态统一落 docs/）
    ├── <slug>.md                          # 单文件（短中篇默认）
    └── <slug>/                            # 多文件（仅当多个独立子主题且各 ≥800 字）
        ├── index.md
        └── <chapter>.md
```
