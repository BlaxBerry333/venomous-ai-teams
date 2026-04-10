# design-team — 设计流程团队

4 个角色驱动的完整设计流程。每个角色在独立 subagent 上下文中运行，互不干扰，通过文件通信。

---

## 角色与命令

| 命令          | 角色                         | 核心职责                                                                    |
| ------------- | ---------------------------- | --------------------------------------------------------------------------- |
| `/产品设计师` | 资深产品设计师 + 设计验证官  | 需求分析、设计方向与风格引导、信息架构、用户流程、设计规格、设计令牌、对抗性设计验证(最多 3 轮) |
| `/UI设计师`   | Staff UI/UX Engineer (15年+) | HTML+CSS 原型制作（线框图 → 高保真）、响应式、语义化、ARIA                  |
| `/设计审查员` | Principal Design QA (15年+)  | 五维审查：规格合规 + 视觉一致性 + 响应式 + 可访问性 + 可用性                |

设计验证官为内部角色，由 `/产品设计师` 自动调度，无需单独调用。

---

## 快速开始

```bash
cp -r teams/design-team/.claude   your-project/
cp -r teams/design-team/__ai__    your-project/

cd your-project && claude
# 输入: /角色命令 你的设计需求
```

### 从零设计

```
1. /产品设计师 描述设计需求
        → 设计规格+设计令牌+对抗性验证
        → phase: spec-done
2. /UI设计师
        → 线框图 + 高保真 HTML+CSS 原型
        → phase: prototype-done
3. /设计审查员
        → 五维设计审查
        → phase: done (或 rework)
4. /UI设计师
        → 修复审查问题 (如有 rework)
5. /设计审查员
        → 复审
6. 浏览器打开 mockup.html 查看最终设计
```

### 交接给 dev-team

```
设计完成后，dev-team 开发时可参考：
- __ai__/design-team/tasks/{任务}/mockup.html     — 视觉原型
- __ai__/design-team/tasks/{任务}/design-tokens.css — 设计令牌
- __ai__/design-team/tasks/{任务}/design-spec.md    — 设计规格
```

---

## 工作流程

```
用户: /产品设计师 设计需求
    │
    ▼
┌── /产品设计师 ─────────────────────────────────────────┐
│                                                       │
│   产品设计师 agent                                      │
│   ├ 分析现有代码/样式 (不信文档)                          │
│   ├ 设计方向与风格参考 (用户关键词/参考/排除)              │
│   ├ 信息架构 + 用户流程 + 组件状态矩阵                     │
│   └ 输出 design-spec.md + design-tokens.css            │
│       + prototype-tasks.md                            │
│       │                                              │
│   调度器 design-lint 确定性校验                          │
│       │                                              │
│       └──> 设计验证官 agent (附 lint 结果)              │
│            ├ 对抗性审查: 用户流程缺口 + 状态矩阵           │
│            │   + 响应式盲点 + 可访问性                    │
│            ├ 直接修补                                  │
│       <── fail 自动循环 (最多 3 轮) <──                 │
│            └ verdict: pass / fail                     │
│                                                      │
└──────────────────── phase: spec-done ────────────────┘
    │
    ▼
┌── /UI设计师 ──────────────────────────────────────────┐
│                                                      │
│   UI设计师 agent                                      │
│   ├ 设计交叉验证                                       │
│   ├ 阶段 1: wireframe.html (低保真线框图)               │
│   ├ 阶段 2: mockup.html (高保真 + 交互)                │
│   │   ├ 设计令牌 100% 应用                              │
│   │   ├ 3 断点响应式                                    │
│   │   ├ 语义化 HTML + ARIA                             │
│   │   └ jQuery 基础交互                                 │
│   └ 自检 6 项 + 交付核查                                 │
│                                                      │
└──────────────────── phase: prototype-done ───────────┘
    │
    ▼
┌── /设计审查员 ────────────────────────────────────────┐
│                                                     │
│   设计审查员 agent                                    │
│   ├ 1. 设计规格合规性                                  │
│   ├ 2. 视觉一致性 (设计令牌 + 硬编码检测)                │
│   ├ 3. 响应式质量 (断点 + 触摸目标)                      │
│   ├ 4. 可访问性 (ARIA + 焦点 + 对比度)                   │
│   └ 5. 可用性启发式 (Nielsen 十原则)                     │
│                                                     │
│   只有 pass   -> done                                 │
│   有 rework   -> /UI设计师                             │
│                                                     │
└──────────────────── phase: done ────────────────────┘
    │
    ▼
浏览器打开 mockup.html 查看最终设计
dev-team 可参考 __ai__/design-team/tasks/{任务}/
```

### 「谁审谁」

```
产品设计师  -->  设计验证官    独立上下文对抗性审查, 最多 3 轮自动循环
UI设计师    -->  设计审查员    独立上下文五维设计审查
```

---

## 状态机

```
        init
         │
         ▼
     researching ◀──── (验证 fail, 最多 3 轮)
         │
         ▼
      spec-done
         │
         ▼
  ┌─▶ prototyping
  │      │
  │      ▼
  │  prototype-done
  │      │
  │      ▼
  │   reviewing ──── (有 rework) ──▶ rework ─┐
  │      │                                   │
  │      ▼ (pass)                            │
  │    done ← 可交付                          │
  │                                          │
  └──────────────────────────────────────────┘
```

command 入口校验 phase，防止跳步骤。中间状态 (researching / prototyping / reviewing) 允许重试。

---

## 权限系统

### 角色权限矩阵

| 文件                     | 产品设计师 | 设计验证官 | UI设计师 | 设计审查员 |
| ------------------------ | :--------: | :--------: | :------: | :--------: |
| `design-spec.md`         |     ✏️     |     ✏️     |    👁️    |     👁️     |
| `design-tokens.css`      |     ✏️     |     👁️     |    👁️    |     👁️     |
| `prototype-tasks.md`     |     ✏️     |     ✏️     |    ☑️    |     👁️     |
| `prototype-plan.md`      |     🚫     |     🚫     |    ✏️    |     👁️     |
| `*.html / assets/**`     |     🚫     |     🚫     |    ✏️    |     👁️     |
| `design-review.md`       |     🚫     |     🚫     |    👁️    |     ✏️     |
| `status.md`              |     ✏️     |     🚫     |    ✏️    |     🚫     |
| `index.md / conventions` |     ✏️     |     🚫     |    🚫    |     🚫     |
| `.claude/**`             |     🚫     |     🚫     |    🚫    |     🚫     |

> ✏️ 可写 · ☑️ 仅勾选 checkbox · 👁️ 只读 · 🚫 禁止

### 三层防线

1. **Hook 拦截** (role-guard.sh) : 基于 `agent_type` 自动拦截越权 Edit/Write
2. **Prompt 约束** : agent prompt 禁止通过 Bash 写文件
3. **事后验证** : 调度器在 agent 返回后执行 git diff 检查变更范围

### 确定性文档校验 (design-lint)

调度器在 spawn 设计验证官之前自动执行 `design-lint.sh`：

- HTML 引用检查：prototype-tasks.md 中引用的 HTML 文件是否存在
- 硬编码颜色检测：HTML 原型中是否有未使用 CSS custom properties 的颜色值
- 响应式断点检查：HTML 原型中 @media 断点是否不足 2 个
- 语义化 HTML 检查：是否缺少 `<main>`、`<nav>`、`role=` 属性
- 关键章节检查：design-spec.md 是否包含设计方向、用户流程、响应式、令牌、可访问性章节

校验结果作为确定性证据传给设计验证官，验证官在此基础上做事实性穷举验证。

---

## 原型输出

### 特点

- **单文件自包含**：内联 CSS + 可选 jQuery CDN，双击浏览器即开
- **设计令牌驱动**：所有视觉值用 CSS Custom Properties (`var(--color-primary)`)
- **3 断点响应式**：640px / 768px / 1024px
- **语义化 HTML5** + ARIA 可访问性属性
- **基础交互**：jQuery（tab 切换、模态框、手风琴、下拉菜单）

### 产出目录

```
__ai__/design-team/
├── index.md                    # 项目设计总览 (产品设计师首次运行生成)
├── conventions.md              # 设计规范 (产品设计师从代码提取)
└── tasks/
    ├── TASKS.md                # 任务索引 (调度器统一更新)
    └── YYYYMMDD_功能名_描述/
        ├── design-spec.md      # 设计规格     - 产品设计师写, 验证官可修正
        ├── design-tokens.css   # 设计令牌     - 产品设计师写
        ├── prototype-tasks.md  # 原型任务清单  - 产品设计师写, UI设计师勾选
        ├── prototype-plan.md   # 原型制作计划  - UI设计师写
        ├── wireframe.html      # 低保真线框图  - UI设计师写
        ├── mockup.html         # 高保真原型    - UI设计师写
        ├── design-review.md    # 审查记录     - 设计审查员写
        └── status.md           # 任务状态     - 调度器更新 phase
```

### 安装后的用户项目

```
your-project/
├── .claude/
│   ├── CLAUDE.md               # 主对话规则
│   ├── settings.json           # 权限配置 + PreToolUse Hook
│   ├── hooks/
│   │   ├── role-guard.sh       # 权限引擎
│   │   └── design-lint.sh      # 设计文档确定性校验
│   ├── agents/
│   │   ├── 产品设计师.md         # 需求分析, 设计规格, 4 个场景
│   │   ├── 设计验证官.md         # 对抗性设计验证, verdict 三值
│   │   ├── UI设计师.md          # HTML+CSS 原型制作, 自检 6 项
│   │   └── 设计审查员.md         # 五维审查
│   ├── commands/
│   │   ├── 产品设计师.md         # 编排设计 + 验证循环
│   │   ├── UI设计师.md          # 编排原型制作 + 产物校验
│   │   └── 设计审查员.md         # 编排审查 + 严重度分级
│   └── templates/
│       ├── design-spec.md       # 设计规格模板 (含验证章节)
│       ├── prototype-tasks.md   # 原型任务清单模板
│       ├── prototype-plan.md    # 原型制作计划模板
│       ├── design-tokens.css    # 设计令牌模板
│       ├── prototype-scaffold.html  # HTML 原型脚手架
│       ├── design-review.md     # 审查记录模板
│       ├── status.md            # 状态 frontmatter 模板
│       └── tasks.md             # 任务索引模板
├── __ai__/
│   └── design-team/
│       └── .gitkeep
└── (用户代码...)
```

---

## 与 dev-team 的协作

design-team 与 dev-team 完全独立，零耦合。协作通过文件引用：

1. design-team 完成设计后，产出在 `__ai__/design-team/tasks/{任务}/`
2. dev-team 的 `/项目经理` 在 design.md 中引用：
   ```
   参考设计原型：__ai__/design-team/tasks/YYYYMMDD_功能名/mockup.html
   参考设计令牌：__ai__/design-team/tasks/YYYYMMDD_功能名/design-tokens.css
   ```
3. 两个团队的 role-guard.sh 各自独立，互不允许写对方目录

---

## 配置

### 模型

各角色默认继承用户当前模型 (inherit)。如需指定，编辑 `.claude/agents/<角色>.md` 的 frontmatter:

```yaml
---
name: UI设计师
description: ...
model: sonnet
tools: ...
---
```

### 语言

当前版本为中文。角色会按 CLAUDE.md 中的语言与用户交互。
