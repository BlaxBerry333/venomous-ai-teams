---
description: web-design-team 全流程：参考拆解（可选）→ 设计师出稿 → 用户拍板 → 执行者建原型 → 审查员并审。中等以上设计任务一键发起
argument-hint: <需求描述，可含参考站 URL>
---

你是 web-design-team 全流程调度。按下方剧本顺序执行，不跳步。**只产设计稿 + 可跑原型，不写业务代码、不接真实数据**。

## 第 0 步：分流

判断 `$ARGUMENTS`：
- 业务页 / 后台 / 表单类需求 → 回："此需求偏业务实现，建议用 /web-dev-team。本 team 服务品牌站 / 落地页 / 官网类视觉密集场景"，**结束**
- 需求过虚（"做个酷的"、"设计个页面"，无具体题目/参考/方向）→ 反问 1-3 个具体问题，**硬断点等用户回**
- 其他 → 进第 1 步

## 第 1 步：参数解析

从 `$ARGUMENTS` 抽：
- **参考站 URL**：含 http(s) 链接 → 待拆解；无 → 跳过第 2 步直接进设计师，让设计师从零设计
- **slug**：按主题生成 kebab-case，后续全程复用，禁 sub-agent 重新推断

## 第 2 步：参考拆解（有 URL 时）

按 `commands/web-design-team/参考拆解.md` 步骤跑，传 URL + slug。

完成后向用户单行播报："拆解完成：refs/<YYYYMMDD_slug>/analysis.md"，**不等确认**直接进第 3 步。

无 URL 时跳过本步。

## 第 3 步：设计师

按 `commands/web-design-team/设计师.md` 跑，传需求 + slug + 拆解报告路径（如有）。

完成后输出**设计稿摘要 5 列汇报表** + design-spec 路径 + 「确认无误请回复 OK；有问题指出我改。回复 OK 后我接执行者 + 审查员」

**硬断点**：等用户回应。

### 反问衔接（设计师反问后的用户回应分流）
- 用户补充需求 → 拿补充后需求**重跑第 3 步**
- 用户沉默 / "算了" / "不做了" → 流程停

## 第 4 步：用户回应分流（设计师已正常出稿后）

**优先级从上到下，命中即停**：
- 含**新需求/新参考站**（如"再加个第二屏复刻 X 站"）→ 回："这是新需求，建议 /web-design-team <新需求> 开新 task"，**停**
- 含 "但 / 不过 / 这里 X 不对 / 改成 Y" → 改 design-spec → 再出汇报表 → 再等
- 含 "OK / 继续 / 走吧 / 没问题" 且无具体修改点 → 进第 5 步
- 沉默 / 关闭 → 流程停

## 第 5 步：执行者

按 `commands/web-design-team/执行者.md` 跑，参数 = design-spec 路径 + 显式标记 `[调度模式]`（让执行者跳过自己的尾部总结，由本调度统一收口）。

执行者会播报一行技术状态（路径 + build 通过 + checklist），不要在调度层重复播报；直接进第 6 步。

## 第 6 步：审查员

按 `commands/web-design-team/审查员.md` 跑（一次消息并行 spawn 三审查员 → 汇总 → 修 → 循环 ≤ 3 轮），参数末尾追加 `[调度模式]`（让审查员跳过自己的最终总结，由本调度统一收口）。

## 第 7 步：最终总结

```
═══ web-design-team 完成 ═══
拆解：__ai__/web-design-team/refs/<...>（无则"无"）
设计稿：__ai__/web-design-team/designs/<YYYYMMDD_slug>/design-spec.md
原型：__ai__/web-design-team/designs/<YYYYMMDD_slug>/prototype/
修复轮次：N（共 M 项已闭环）
═══
查看：cd <原型路径> && npm install && npm run dev
后续：
  调整 → 直接说哪不对，本对话内主对话 Edit
  开新 task → /web-design-team <新需求>
  上下文偏长 → /compact 或开新对话凭 design-spec 路径续接
  下游对接 → web-dev-team 或真人前端 Read design-spec.md 即可接
```

## 用户需求

$ARGUMENTS
