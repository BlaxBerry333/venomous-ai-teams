# design-team — 设计团队（单角色 + 可选独立审查）

直接在主上下文中执行的设计师角色。调用一次命令后角色能力在当前对话中持续生效。

可选的独立审查 SubAgent 仅在用户主动要求"严格审查"时由 `/设计师` 自动调度。

---

## 角色与命令

| 命令 | 角色 | 核心职责 |
|------|------|---------|
| `/设计师` | 资深产品设计师 + UI/UX 工程师 + 设计系统架构师 | 设计现状摸底 / 新设计任务 / 迭代修改 / 调度独立审查 |

> 设计审查 SubAgent 不直接暴露给用户，由 `/设计师` 在用户喊「严格审查 / 独立审一下 / 找毛病」时按需 spawn。

---

## 快速开始

```bash
# 推荐：交互式安装（支持多团队合并）
bash setup.sh

# 或手动复制（仅单团队使用时）
cp -r teams/design-team/.claude   your-project/
cp -r teams/design-team/__ai__    your-project/

cd your-project && claude
# 输入: /设计师 你的设计需求
```

### 典型用法

```
/设计师 设计 B 端 SaaS 项目管理 console 主页
        → 前置问答（按任务规模分档：3/4/7 项）
        → 写 design-brief.md + design-tokens.css + prototype.html
        → 跑 design-lint + 设计自检
        → 登记 TASKS.md

颜色再亮一点                           ← P4：修正词，定位现有任务迭代
把侧边栏换成可折叠的                    ← 同上
新开一个登录页设计                     ← P2：新开词，新建任务目录
严格审查一下                          ← P1：spawn 独立审查 SubAgent
```

### 追加需求 / 迭代修改

开发过程中追加或修改需求，在原任务上继续，不新建目录：

```
/设计师 设计登录页              ← 新建任务
颜色再亮一点                    ← 修正词 → P4，定位刚才的任务，改 tokens
按钮改成幽灵                    ← 同上
加一个空状态                    ← 追加词 → P4，同上
```

**触发词**（场景判定识别，详见 `commands/设计师.md`）：
- 追加词：`再加` `还要` `补充` `顺便` `另外` `加一个`
- 修正词：`改成` `改为` `不对` `应该是` `有问题` `重做` `换成` `亮一点` `深一点`
- 指代词：`这个` `刚才那个` `那个任务` `上次的`
- 新开词：`新开` `另起` `单独做` `新任务` `新的页面`

**新会话保护**：新对话中 `/设计师` 仍会读 `TASKS.md` 找未完成任务作候选，根据触发词正确归属。

---

## 核心特性

### 设计前置问答（按任务规模分档）

不一刀切全问。按任务规模走不同通道：

- **快速通道**（组件改动 / 样式微调）：3 项
- **标准通道**（tokens / 设计规范 / 组件库）：4 项
- **完整通道**（完整页面 / 落地页 / Dashboard）：7 项

**底线**：至少有一个风格锚点（参考网址 / 风格关键词 / 具体值 / 截图），没有不动手。

### 反 AI 烂设计清单（13 项）

prompt 内置 13 项 AI 默认陷阱（视觉 10 项 + Token 体系 3 项），出原型前自检命中即重做。`design-lint.sh` 也机械检测部分信号。

### 设计系统 tokens（技术体系适配）

`templates/design-tokens.css` 是参考脚手架（Radix 风格分层），不是强制模板：

- 用户已有 Tailwind / Material / 自研体系 → 延续用户体系
- 用户没有设计体系 → 参考模板分层思路创建

Tailwind 项目直接引入 CDN 用 utility class 写原型。

### 确定性原型校验（design-lint）

`/设计师` 完成原型后自动跑 `design-lint.sh`（13 项机械检查：硬编码检测、响应式断点、语义 HTML、ARIA、Typography 成对、反 AI 信号等）。`[WARN]` 当轮修完。

### 可选独立审查

用户喊「严格审查」→ spawn `设计审查` SubAgent，干净 context 独立审 7 维（规格合规 / 风格锚一致性 / Token 体系合规 / 视觉一致 / 响应式 / 可访问性 / Nielsen 启发式）。

### 上下文质量保障

- **产出写文件，对话只输出摘要**
- **操作前重读，不凭记忆**
- **跨任务建议 `/compact`** — `/设计师` < 7000 tokens，compact 后自动重新附加

---

## 权限系统

### 路径硬拦截（path-guard）

`PreToolUse` hook 基于路径判断，与 agent 身份无关。禁区：

- `.claude/**` — 框架配置
- `app/**` — 应用代码（dev-team 负责）
- `__ai__/dev-team/**` — dev-team 领地
- `__ai__/docs-team/**` — docs-team 领地

**用户授权不是跨团队豁免**：hook 仍 deny。需修改请切换到对应团队角色。

### 文件权限矩阵

| 文件 | 设计师 |
|------|:------:|
| `__ai__/design-team/**` | ✏️ |
| 用户项目代码 | 🚫 |
| `.claude/**` | 🚫 |
| 其他团队 `__ai__/` | 🚫 |

> ✏️ 可写 · 🚫 禁止

> **为何不用 role-guard.sh**：Command 注入模型在主对话执行，hook 拿不到 `agent_type`。改用基于路径的 path-guard 硬拦截，与 docs-team 同模式。

---

## 文件结构

### 产出目录

```
__ai__/design-team/
├── index.md                        # 项目设计总览（场景一生成）
├── conventions.md                  # 设计规范（从代码归纳）
└── tasks/
    ├── TASKS.md                    # 任务索引（场景判定时查询用）
    └── YYYYMMDD_功能名_描述/
        ├── design-brief.md         # 设计简报
        ├── design-tokens.css       # 设计令牌（dev-team 接口）
        ├── prototype.html          # HTML+CSS 原型
        ├── status.md               # 任务状态 + 变更记录
        ├── static/                 # （可选）参考资源
        └── design-review.md        # （可选）独立审查报告
```

### 安装后的用户项目

```
your-project/
├── .claude/
│   ├── CLAUDE.md                       # 主对话规则
│   ├── settings.json                   # 权限配置 + hook 绑定
│   ├── hooks/
│   │   ├── path-guard.sh               # 路径禁区硬拦截（PreToolUse）
│   │   └── design-lint.sh              # 原型确定性校验（13 项）
│   ├── commands/
│   │   └── 设计师.md                    # 设计师角色（主对话直接执行）
│   ├── agents/
│   │   └── 设计审查.md                  # 可选独立审查 SubAgent
│   └── templates/
│       ├── design-brief.md             # 设计简报模板
│       ├── design-tokens.css           # 设计令牌参考脚手架
│       ├── prototype-scaffold.html     # HTML 原型脚手架
│       ├── status.md                   # 任务状态模板
│       └── TASKS.md                    # 任务索引模板
└── __ai__/
    └── design-team/
        └── .gitkeep
```

---

## 与 dev-team 的协作

design-team 与 dev-team 完全独立。协作通过文件引用：

1. design-team 产出在 `__ai__/design-team/tasks/{任务}/`
2. dev-team 的 `/项目经理` 在 design.md 中引用 prototype.html / design-tokens.css / design-brief.md
3. 两个团队的 hook 各自独立，互不允许写对方目录

---

## 配置

### 模型

`/设计师` 是 command（主对话执行），继承用户当前模型。设计工作不涉及复杂多 agent 调度或深度代码推理，**Sonnet 即可胜任**，无需 Opus。

`设计审查` SubAgent 已在 frontmatter 中固定 `model: sonnet`，无论用户主对话用什么模型，审查都跑 Sonnet。

### 语言

- 与用户对话：按用户使用的语言
- 文档正文：按现有项目文档风格
- 代码 / token 名 / CSS 属性：英文
