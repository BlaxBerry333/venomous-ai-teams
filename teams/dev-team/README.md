# dev-team — 开发流程团队

4 个角色驱动的完整开发流程。每个角色在独立 subagent 上下文中运行，互不干扰，通过文件通信。

---

## 角色与命令

| 命令          | 角色                        | 核心职责                                                          |
| ------------- | --------------------------- | ----------------------------------------------------------------- |
| `/项目经理`   | CTO 级架构师                | 需求分析、影响分析(三层穷举)、任务拆分、强制设计自检(关键假设/高风险决策/未覆盖边界) |
| `/程序员`     | Staff Engineer (15年+)      | 分阶段实现、静态自检 9 项、设计交叉验证、编写回归测试             |
| `/代码审查员` | Principal QA (15年+)        | 6 维全量审查 + 构建/测试/lint/冒烟/回归冒烟执行验证               |
| `/测试员`     | Principal SDET (15年+ 可选) | 测试策略设计、测试代码编写与执行、设计问题反馈                    |

> 说明：设计质量由**项目经理自检三表 + 调度器确定性校验（grep 影响范围 + doc-lint）+ 用户审阅摘要**三层保证，不再使用独立 LLM 验证官（同模型二次审查在统计上不独立，性价比低）。

---

## 快速开始

```bash
# 推荐：交互式安装（单团队；切换到其他团队请重跑 setup.sh）
bash setup.sh

# 或手动复制（等价于交互式安装的效果）
cp -r teams/dev-team/.claude   your-project/
cp -r teams/dev-team/__ai__    your-project/

cd your-project && claude
# 输入: /角色命令 你的需求描述
```

### 从零开发

```
1. /项目经理 描述需求
        → 设计 + 强制自检三表 + 确定性校验 + 展示摘要给用户
        → 用户审阅摘要 → phase: verified
2. /程序员
        → 实现代码
        → phase: dev-done
3. /代码审查员
        → 审查+执行验证
        → phase: review-passed (或 rework)
4. /程序员
        → 修复问题 (如有 rework)
5. /测试员 (可选)
        → 测试
        → phase: done (或 rework)
6. /程序员
        → 修复测试问题 (如有 rework)
7. 用户手动 git merge
8. /项目经理 更新项目文档
```

### 接手他人分支

```
1. /项目经理 接手分析，并描述后续需求
2. /程序员
        → 修复问题 + 继续开发
3. 后续同从零开发的步骤 3-8
```

### 追加需求 / 需求变更（任务进行中）

开发过程中追加或变更需求，在原任务上继续，不新建任务目录：

```
任务 A 正在 developing/reviewing/testing...
    │
    ▼
用户: /项目经理 再加个 X  (或 "改成 Y" / "这里不对")
        → 调度器识别追加/修正词 + 当前未完成任务
        → phase 退回 designing，TASKS.md 同步回退
        → agent 按场景 3 在原 design.md/dev-tasks.md 上增量更新
        → 变更记录写入 status.md 变更记录表
        → agent 重新自检 + 调度器重跑确定性校验
        → phase: verified → 用户审阅摘要后调用 /程序员
    │
    ▼
继续原流程: /程序员 → /代码审查员 → ...
```

**触发词**（调度器识别，详见 `commands/项目经理.md` 步骤 1.2）：

- 追加词：`再加 / 还要 / 补充 / 顺便 / 另外 / 加一个 / 加上`
- 修正词：`改成 / 改为 / 不对 / 不是这样 / 应该是 / 有问题 / 重做 / 换成`
- 指代词：`这个 / 刚才那个 / 上面那个 / 那个任务 / 现在这个`
- 若想**新建**独立任务而非在原任务上改，用新开词：`新开 / 另起 / 单独做 / 新任务 / 新需求独立`

---

## 工作流程

```
用户: /项目经理 需求描述
    │
    ▼
┌── /项目经理 ──────────────────────────────────────────┐
│                                                      │
│   项目经理 agent                                      │
│   ├ 阅读实际代码 (不信文档)                             │
│   ├ 影响分析三层穷举                                   │
│   ├ 强制设计自检三表(关键假设/高风险决策/未覆盖边界)      │
│   └ 输出 design.md + dev-tasks.md + 结构化摘要         │
│       │                                              │
│   调度器 grep 影响范围 + doc-lint 确定性校验             │
│       │                                              │
│       └──> 展示给用户：摘要 + 校验结果                  │
│            用户审阅 → 确认执行 /程序员，或               │
│            用户回修正词触发 /项目经理 迭代设计           │
│                                                      │
└──────────────────── phase: verified ────────────────┘
    │
    ▼
┌── /程序员 ───────────────────────────────────────────┐
│                                                     │
│   程序员 agent                                       │
│   ├ 设计交叉验证                                      │
│   ├ 分阶段实现 + 每阶段自检 9 项                        │
│   ├ 处理 [回归验证] 任务 -> 编写回归测试                 │
│   └ 交付前重新读文件核查 (不凭记忆)                      │
│                                                     │
└──────────────────── phase: dev-done ────────────────┘
    │
    ▼
┌── /代码审查员 ───────────────────────────────────────┐
│                                                    │
│   代码审查员 agent                                   │
│                                                    │
│   Part 1: 代码审查 (看代码)                          │
│   ├ 6 维全量审查 (复审也做全量)                        │
│   └ 验收标准核实 + 设计缺陷标注                         │
│                                                     │
│   Part 2: 执行验证 (跑代码)                           │
│   ├ 构建 (npm run build / go build / ...)           │
│   ├ 已有测试 (npm test / pytest / ...)               │
│   ├ Lint / 类型检查                                  │
│   ├ 冒烟验证 (curl / 脚本)                            │
│   └ 回归冒烟验证                                      │
│                                                     │
│   只有 green  -> review-passed                       │
│   有 yellow/red -> rework -> /程序员                 │
│                                                     │
└──────────────────── phase: review-passed ───────────┘
    │
    ▼
┌── /测试员 (可选) ────────────────────────────────────┐
│                                                    │
│   前置: conventions.md 有测试策略 + 测试文件范围        │
│                                                     │
│   测试员 agent                                       │
│   ├ 测试策略设计 + 测试代码编写                         │
│   └ 执行测试 + 失败分析                                │
│     (区分 代码bug / 测试bug / 设计问题)                │
│                                                     │
│   全部通过 / 仅 green -> done                         │
│   有 yellow/red       -> rework -> /程序员           │
│                                                     │
└──────────────────── phase: done ────────────────────┘
    │
    ▼
用户 git merge
    │
    ▼
/项目经理 更新项目文档
```

### 「谁审谁」

```
项目经理  -->  自检+调度器    设计自检三表 + grep 影响范围 + doc-lint 确定性校验 + 用户审阅摘要
程序员    -->  代码审查员    独立上下文 6 维审查 + Bash 执行验证
程序员    -->  测试员       独立上下文测试编写与执行
```

执行验证 = 代码审查员用 Bash 实际运行代码。程序员写代码，代码审查员跑代码。结果是事实，不是 LLM 推测。

---

## 状态机

```
        init
         │
         ▼
      designing ◀──── (用户不满意摘要，用修正词触发迭代)
         │
         ▼
      verified
         │
         ▼
  ┌─▶ developing
  │      │
  │      ▼
  │   dev-done
  │      │
  │      ▼
  │   reviewing ──── (有 yellow/red) ──▶ rework ─┐
  │      │                                       │
  │      ▼ (只有 green)                          │
  │   review-passed                             │
  │      │                                      │
  │      ├─── (无测试策略) ──▶ done ← 可合并       │
  │      │                                      │
  │      ▼ (有测试策略)                           │
  │   testing ───── (有 yellow/red) ──▶ rework  ─┤
  │      │                                       │
  │      ▼ (只有 green)                          │
  │    done ← 可合并                              │
  │                                              │
  └──────────────────────────────────────────────┘

额外转移（P0-1 引入）：追加/修正需求
  任何 { designing | verified | developing | dev-done |
         reviewing | review-passed | testing | rework }
     │
     │  用户用 /项目经理 + 追加词/修正词/指代词 触发
     │  调度器识别 → status.md 和 TASKS.md 退回 designing
     ▼
  designing  (重新自检 + 重跑确定性校验，展示新摘要给用户)
```

说明：

- **设计迭代**：`designing → designing`（用户看过摘要觉得要调整，用追加/修正词 `/项目经理 改成 X` 触发，在原 design.md 上增量更新）
- **reviewer/tester rework**：`reviewing/testing → rework → developing`（rework_reason 记录来源，供程序员区分返工原因）
- **需求变更**（P0-1）：任何未完成状态 → `designing`，原 phase 记录到 status.md 变更记录表；若原 phase 为 `rework`，调度器会同时清空 `rework_reason`（原返工原因已被新需求覆盖）
- command 入口校验 phase，防止跳步骤。中间状态 (designing / developing / reviewing / testing) 允许重试

---

## 权限系统

### 角色权限矩阵

| 文件                   | 项目经理 | 程序员 | 代码审查员 | 测试员 |
| ---------------------- | :------: | :----: | :--------: | :----: |
| `design.md`            |    ✏️    |   👁️   |     👁️     |   👁️   |
| `dev-tasks.md`         |    ✏️    |   ☑️   |     👁️     |   👁️   |
| `dev-plan.md`          |    🚫    |   ✏️   |     👁️     |   👁️   |
| `review.md`            |    🚫    |   👁️   |     ✏️     |   👁️   |
| `test-report.md`       |    🚫    |   👁️   |     🚫     |   ✏️   |
| `status.md`            |    ✏️    |   ✏️   |     🚫     |   🚫   |
| `index.md/conventions` |    ✏️    |   🚫   |     🚫     |   🚫   |
| 项目代码               |    🚫    |   ✏️   |     🚫     |   ✏️   |
| `.claude/**`           |    🚫    |   🚫   |     🚫     |   🚫   |

> ✏️ 可写 · ☑️ 仅勾选 checkbox · 👁️ 只读 · 🚫 禁止

### 三层防线

1. **Hook 拦截** (role-guard.sh) : 基于 `agent_type` 自动拦截越权 Edit/Write
2. **Prompt 约束** : agent prompt 禁止通过 Bash 写文件
3. **事后验证** : 调度器在 agent 返回后执行 git diff 检查变更范围

### 确定性文档校验 (doc-lint)

代码有 tsc/eslint/build/test 兜底，文档也需要确定性校验。调度器在 agent 产出 design.md 后自动执行 `doc-lint.sh`：

- 文件存在性：design.md 中引用的文件是否真的存在
- API 端点计数：design.md 声称的端点数 vs 项目 router 中的实际定义数
- 影响分析覆盖：影响分析中的每个条目是否在 dev-tasks.md 中有对应任务
- 任务文件引用：dev-tasks.md 中引用的文件路径是否存在

校验结果直接展示给用户，与 agent 的结构化摘要一起作为审阅依据。

---

## 文件结构

### 产出目录

```
__ai__/dev-team/
├── index.md                 # 项目总览 (项目经理首次运行生成)
├── conventions.md           # 编码规范 (项目经理从代码提取)
└── tasks/
    ├── TASKS.md             # 任务索引 (调度器统一更新)
    ├── YYYYMMDD_功能名_描述/
    │   ├── design.md        # 设计书       - 项目经理写（含「设计自检」三表）
    │   ├── dev-tasks.md     # 任务清单     - 项目经理写, 程序员勾选
    │   ├── dev-plan.md      # 开发计划     - 程序员写
    │   ├── status.md        # 任务状态     - 调度器更新 phase
    │   ├── review.md        # 审查记录     - 代码审查员写
    │   └── test-report.md   # 测试报告     - 测试员写
    └── YYYYMMDD_quickfix_描述/
        └── quickfix-log.md  # 快速修复记录 - 不走流程时生成
```

### 安装后的用户项目

```
your-project/
├── .claude/
│   ├── CLAUDE.md            # 主对话规则 (角色调用, 累积感知, 行为约束)
│   ├── settings.json        # 权限配置 + PreToolUse Hook 绑定
│   ├── hooks/
│   │   ├── role-guard.sh    # 权限引擎 (基于 agent_type 匹配角色)
│   │   └── doc-lint.sh      # 设计文档确定性校验 (调度器调用)
│   ├── agents/              # 角色 prompt (subagent 独立加载, 不进主上下文)
│   │   ├── 项目经理.md        # 需求分析, 系统设计, 强制设计自检, 5 个场景
│   │   ├── 程序员.md         # 代码实现, 自检 9 项, 回归测试
│   │   ├── 代码审查员.md      # 6 维审查 + 执行验证
│   │   └── 测试员.md         # 测试策略 + 编写 + 执行
│   ├── commands/            # 调度器 (主上下文执行, ~100行/个, 极低 token)
│   │   ├── 项目经理.md       # 编排设计 + 确定性校验 + 展示摘要给用户
│   │   ├── 程序员.md         # 编排开发 + 产物校验
│   │   ├── 代码审查员.md      # 编排审查 + 严重度分级
│   │   └── 测试员.md         # 编排测试 + 测试范围提取
│   └── templates/           # 文档模板 (角色创建文档前先读模板)
│       ├── design.md        # 设计书模板 (含设计自检三表)
│       ├── dev-tasks.md     # 任务清单模板
│       ├── dev-plan.md      # 开发计划模板
│       ├── status.md        # 状态 frontmatter 模板
│       ├── tasks.md         # 任务索引模板
│       ├── review.md        # 审查记录模板
│       ├── test-report.md   # 测试报告模板
│       └── quickfix-log.md  # 快速修复记录模板
├── __ai__/
│   └── dev-team/            # 团队产出目录
│       └── .gitkeep
└── (用户代码...)
```

---

## 配置

### 模型

各角色默认继承用户当前模型 (inherit)。如需指定，编辑 `.claude/agents/<角色>.md` 的 frontmatter:

```yaml
---
name: 代码审查员
description: ...
model: sonnet
tools: ...
---
```

### 语言

当前版本为中文。角色会按 CLAUDE.md 中的语言与用户交互。
