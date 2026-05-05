# web-dev-team

[English](./README.md) | 中文 | [日本語](./README.ja.md)

## 是什么

逼 Claude 在 web 全栈任务上**先想清楚再写**：架构者管全栈决策、执行者填实现、独立 sub-agent 复审。

## 工作流 + 特点

`/web-dev-team <需求>` → 架构者出 spec + 汇报表 → 你回 OK → 执行者改 → 三审查员并审 → 修 → 完工。

- **强制给选型理由**：`选型：` 前缀必须带一行 web 知识理由
- **真独立审查**：3 个 sub-agent 各自上下文，不是 LLM 自审
- **全程可追溯**：spec / 汇报表 / 审查发现都落盘
- **小需求绕过**：typo 直跑、需求过虚反问，不烧全流程

## 角色

| 角色 | 干啥 | 不干啥 |
|---|---|---|
| **架构者** | 全栈决策 → 出 spec + 5 列汇报表 | 不写代码 |
| **执行者** | 照 spec 填实现细节 → 改代码 | 不改 spec、不动重决策 |
| **审查员** | 调度 3 个 sub-agent 三切面正交并审 | 不写代码、不改 spec |

## 对比第三方（数据 2026-05）

| 维度 | web-dev-team | BMad Method | Spec Kit | Claude Skills |
|---|:---:|:---:|:---:|:---:|
| Spec 闭环 | ✅ | ✅ | ✅ | ❌ |
| 真独立 sub-agent 审查 | ✅<br/>三切面正交 | ⚠️<br/>同会话 persona | ⚠️<br/>需社区扩展 | ❌ |
| Hook 防误改<br/>（exit 2 真阻断） | ✅ | ❌ | ⚠️<br/>需扩展 | ❌ |
| 行数硬规<br/>（防 prompt 膨胀） | ✅ | ❌ | ❌ | N/A |
| 「选型」强制给理由 | ✅ | ❌ | ⚠️<br/>间接 | ❌ |
| 多 team 共存 | ✅<br/>命名空间隔离 | ❌ | ❌ | ⚠️<br/>组织级 |
| 平台 | Claude Code | 多 IDE | 多平台 | Claude 全产品 |
| 单次中等需求成本 | $0.35-1.75 | $1-10 | 变动 | $0.01-0.1 |

## 使用

### 安装/删除

```bash
bash setup.sh   # 交互式选 install / remove + team + 目标项目
```

### 命令

| 命令 | 干啥 |
|---|---|
| `/web-dev-team <需求>` | 全流程<br/>架构者 → 用户确认 → 执行者 → 三审查员（≤ 3 轮修复闭环） |
| `/web-dev-team:架构者 <需求>` | 单跑架构者<br/>产 `/__ai__/web-dev-team/specs/YYYYMMDD_<slug>.md` |
| `/web-dev-team:执行者 <spec路径或裸需求>` | 单跑执行者<br/>照 spec 改代码 |
| `/web-dev-team:审查员` | 无参数<br/>默认审 git diff 未提交改动 |
| `/web-dev-team:审查员 <路径或范围>` | 带参数<br/>审指定文件/目录/git ref |

### 装后目录结构（你的项目里）

```
<你的项目>/
├── .claude/
│   ├── commands/
│   │   ├── web-dev-team.md              # /web-dev-team 入口（全流程调度）
│   │   └── web-dev-team/
│   │       ├── 架构者.md                # /web-dev-team:架构者
│   │       ├── 执行者.md                # /web-dev-team:执行者
│   │       └── 审查员.md                # /web-dev-team:审查员（调度三 sub-agent）
│   ├── agents/web-dev-team/             # 三个独立 sub-agent
│   │   ├── 审查员-逻辑审查.md
│   │   ├── 审查员-现有影响审查.md
│   │   └── 审查员-需求复审.md
│   ├── hooks/web-dev-team/              # PreToolUse hook
│   │   ├── path-guard.sh                # 阻断 sub-agent 写入 .claude/
│   │   └── spec-required.sh             # 多文件改动无 spec 时提醒
│   ├── templates/web-dev-team/
│   │   └── spec-template.md             # spec 八节模板（运行拓扑节按需出现）
│   └── .fragments/web-dev-team.json     # hook + permissions 片段（合成进 settings.json）
│
└── __ai__/
    └── web-dev-team/                    # 你的产物（删除 team 时保留）
        └── specs/
            └── YYYYMMDD_<slug>.md       # 架构者写的 spec
```

