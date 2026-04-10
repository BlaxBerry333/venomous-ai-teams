# UI设计师（调度器）

调度 UI设计师 完成 HTML+CSS 原型制作。调度器只做编排，不写原型代码，但可读写 status.md（phase/rework_reason）和 TASKS.md（状态列）。

---

## 步骤

### 1. 定位任务

- **用户提供了路径** → 直接使用
- **用户未提供** → 执行 `ls -t __ai__/design-team/tasks/` 找最近修改的目录，向用户确认"是否处理 __ai__/design-team/tasks/XXX？"，确认后继续

### 2. 校验 phase

读取 status.md frontmatter 中的 `phase` 值。

- **phase ∈ {spec-done, rework, prototyping}** → 继续
- **其他值** → 提示用户当前 phase 不允许原型制作，停止执行

### 3. 更新 phase

写 status.md：`phase: prototyping`，`updated: {今天日期}`。更新 TASKS.md 状态列为 `prototyping`。

### 4. spawn UI设计师

用 Agent 工具 spawn，name 设为 `UI设计师`。prompt 中包含：

- 任务目录路径
- **如 phase 来自 rework**：提示 UI设计师先读 status.md 的 `rework_reason` 字段确定返工来源，再读对应的 `design-review.md` 获取具体问题
- 要求返回 ≤200 字摘要

### 5. 事后验证（UI设计师）

执行 `git diff --name-only` + `git status --short`，检查以下文件未被修改：

- `__ai__/design-team/index.md`
- `__ai__/design-team/conventions.md`
- 任务目录下的 `design-spec.md`、`design-tokens.css`、`design-review.md`
- `.claude/**`

如有越权修改，警告用户并建议 revert。

### 5.5 prototype-plan.md 关键章节检查

用 grep 检查 prototype-plan.md 是否包含关键章节标题：

- `交付核查` — 缺失则警告"prototype-plan.md 缺少交付核查章节，无法确认交付完整性"
- `原型文件清单` — 缺失则警告"prototype-plan.md 缺少原型文件清单"

警告不阻塞流程，但展示给用户知晓。

### 6. 产物校验

读取 `prototype-tasks.md`，检查是否有未勾选项（`[ ]`，兼容 `- [ ]` 和 `1. [ ]` 等格式）。

- **有未勾选项** → 不更新 phase，在输出中提示仍有未完成任务
- **全部勾选** → 继续

同时检查至少 `mockup.html` 存在于任务目录中。

- **不存在** → 警告"缺少 mockup.html 高保真原型文件"

### 7. 更新 phase

写 status.md：`phase: prototype-done`，`updated: {今天日期}`。

### 8. 更新 TASKS.md

更新本任务状态列：`prototyping` → `prototype-done`。

### 9. 收尾

- 向用户展示 UI设计师摘要
- 提示下一步：`/设计审查员 __ai__/design-team/tasks/{任务目录}/`
- 提醒用户：可在浏览器中打开 `mockup.html` 预览原型效果
  - 如 rework_reason 非空，额外说明：修复后的原型需经审查确认

---

## 用户指令

$ARGUMENTS
