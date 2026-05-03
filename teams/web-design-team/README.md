# web-design-team

中文 | [English](./README.en.md) | [日本語](./README.ja.md)

## 是什么

逼 Claude 在品牌站 / 落地页 / 官网类视觉密集任务上**先参数化设计再实现**：拆解者扒参考站（给了 URL 才跑，没给就从零设计）、设计师出 design-spec、执行者搭可跑原型、3 个 sub-agent 并审。**只产设计稿 + 原型，不接业务数据**。

## 工作流 + 特点

`/web-design-team <需求 + 参考站 URL>` → 拆参考站（有 URL 才跑）→ 设计师出 spec + 5 列汇报表 → 你回 OK → 执行者搭原型 → 3 个 sub-agent 并审 → 修。

- **参考站逆向拆解**：动效手法 / 资产 / 复刻难度都从抓帧扒出来，不靠看截图猜
- **动效参数化**：duration / easing / 触发 / 起止四件套必填，"流畅自然"这类虚词被禁
- **占位可下游对接**：spec §5 给真品规格 + 替换路径，下游（web-dev-team / 真人前端）直接接
- **真独立审查**：还原度 / 性能 / 可访问性 3 个 sub-agent 各自上下文，不是 LLM 自审

## 角色

| 角色 | 干啥 | 不干啥 |
|---|---|---|
| **参考拆解者** | 扒参考站技术栈 + 资产 + 动效清单 → 落 refs/ | 不设计、不写代码 |
| **设计师** | 出 design-spec（分区/组件/动效参数/资产清单/性能预算）+ 5 列汇报表 | 不写代码 |
| **执行者** | 拷模板 + 按 spec 搭可跑原型（默认 React+Vite+framer-motion 轻装；r3f / gsap / lucide 由 spec §8 声明时按需加） | 不动 spec、不联网下真资产 |
| **审查员** | 调度 3 个 sub-agent 正交并审（还原度 / 性能 / 可访问性） | 不写代码、不改 spec |

## 对比第三方（数据 2026-05）

| 维度 | web-design-team | v0.dev | Galileo AI | Framer AI |
|---|:---:|:---:|:---:|:---:|
| 参考站逆向拆解 | ✅<br/>WebFetch / Playwright | ❌ | ❌ | ❌ |
| 3D / WebGL 原型 | ✅<br/>r3f + drei | ⚠️<br/>有限 | ❌ | ⚠️<br/>受限 |
| 动效参数化设计稿 | ✅<br/>含 easing/duration/触发 | ❌<br/>只产代码 | ❌ | ⚠️ |
| 设计稿可下游对接 | ✅<br/>md 结构化 | ❌ | ❌ | ❌<br/>锁平台 |
| 占位资产清单 | ✅<br/>含真品规格 + 替换路径 | ❌ | ❌ | ❌ |
| 3 个 sub-agent 独立审查 | ✅<br/>还原度/性能/a11y | ❌ | ❌ | ❌ |
| 平台 | Claude Code | SaaS | SaaS | SaaS |
| 单次中等需求成本 * | $0.5-2.5 | $20/月起 | $19/月起 | $15/月起 |

\* 估算，含设计师 + 执行者 + 3 个 sub-agent 并审；实际取决于动效复杂度 + 模型 + 是否走全流程，简单页可低至 $0.2，重 3D + 多轮修复可达 $4+。

## 使用

### 安装/删除

```bash
bash setup.sh   # 交互式选 install / remove + team + 目标项目
```

### 命令

| 命令 | 干啥 |
|---|---|
| `/web-design-team <需求>` | 全流程<br/>参考拆解（如有 URL）→ 设计师 → 用户确认 → 执行者 → 3 个 sub-agent 并审（≤ 3 轮修复闭环） |
| `/web-design-team:参考拆解 <URL>` | 单跑参考拆解者<br/>产 `refs/<YYYYMMDD_slug>/analysis.md` |
| `/web-design-team:设计师 <需求>` | 单跑设计师<br/>产 `designs/<YYYYMMDD_slug>/design-spec.md` |
| `/web-design-team:执行者 <design-spec 路径>` | 单跑执行者<br/>按 spec 搭原型，**完工前必须 tsc + vite build 通过** |
| `/web-design-team:审查员 <design-spec 路径>` | 审指定 design<br/>≥2 份 design 时强制带参；唯一 1 份可省略 |

### 装后目录结构（你的项目里）

```
<你的项目>/
├── .claude/
│   ├── commands/
│   │   ├── web-design-team.md            # /web-design-team 入口（全流程调度）
│   │   └── web-design-team/
│   │       ├── 参考拆解.md                # /web-design-team:参考拆解
│   │       ├── 设计师.md                  # /web-design-team:设计师
│   │       ├── 执行者.md                  # /web-design-team:执行者
│   │       └── 审查员.md                  # /web-design-team:审查员（调度 3 个 sub-agent）
│   ├── agents/web-design-team/           # 三个独立 sub-agent
│   │   ├── 审查员-还原度.md
│   │   ├── 审查员-性能.md
│   │   └── 审查员-可访问性.md
│   ├── hooks/web-design-team/            # PreToolUse hook
│   │   └── path-guard.sh                 # 阻断 sub-agent 写入 .claude/
│   ├── templates/web-design-team/
│   │   ├── analysis-template.md          # 参考拆解者用
│   │   ├── design-spec-template.md       # 设计师用
│   │   └── prototype-skeleton/           # 执行者拷贝的 Vite+React 模板
│   └── .fragments/web-design-team.json   # hook + permissions 片段（合成进 settings.json）
│
└── __ai__/
    └── web-design-team/                  # 你的产物（删除 team 时保留）
        ├── refs/<YYYYMMDD_slug>/         # 参考拆解产物
        │   └── analysis.md
        └── designs/<YYYYMMDD_slug>/
            ├── design-spec.md            # 设计师写的 spec
            └── prototype/                # 可跑原型（npm install && npm run dev）
                ├── README.md             # 本 design 专属说明（执行者重写，非模板默认）
                └── placeholder-todo.md   # §5 占位资产 checklist，下游接手时勾选
```

## 下游对接

下游 team（如 web-dev-team / 真人前端）拿到 design 后：

1. Read `designs/<slug>/design-spec.md` 看 §2 组件树 / §3 token / §4 动效参数 / §7 性能预算
2. Read `designs/<slug>/prototype/README.md` 看本 design 是干啥的 + 怎么跑
3. Read `designs/<slug>/prototype/placeholder-todo.md` 逐项把占位换成真品
4. 真品替换完 → prototype 已升级到生产可用资产；可直接迁移到目标项目栈

> **响应式范围**：本 team 产物仅按 1024+ 桌面演示视觉与交互；移动端响应式由下游 team 按目标项目断点系统（如 Tailwind/MUI/自有栅格）适配。design-spec §7 mobile 节标了降级意图（哪些动效/3D 关或简化、hero 是否竖排）供参考，断点细节归下游。

## 软依赖

- **Node.js + npm**：跑原型需要（Vite 项目）
- **Playwright**（**强烈建议**，技术上可选）：参考拆解阶段抓滚动帧 + 动效录制；不装则降级到 WebFetch 只能拿静态 HTML，**滚动 / hover / mousemove 类动效全靠脑补**——参考拆解的核心价值废大半。装一次 `npx playwright install chromium` 即可
