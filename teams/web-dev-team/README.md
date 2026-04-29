# web-dev-team

Web 开发方向的专业 team。**当前为占位骨架**——具体角色 / 命令 / hook 留待下一轮设计。

## 已锁定的命名约定

| 资源 | 路径 | 用户触发 |
|---|---|---|
| slash command | `.claude/commands/web-dev-team/<中文名>.md` | `/web-dev-team:<中文名>` |
| sub-agent | `.claude/agents/web-dev-team/<英文名>.md`，frontmatter `name: web-dev-team-<英文名>` | 由命令 spawn |
| hook | `.claude/hooks/web-dev-team/<英文名>.sh` | settings.json 注册 |
| 输出目录 | `__ai__/web-dev-team/` | team 写入 |

## 设计原则（继承自架构定稿）

- 单 sub-agent prompt ≤ 60 行
- 简单需求（改 1-2 文件）零 sub-agent 调用
- 完整 design + review 流程 ≤ 1 次 sub-agent 调用
- 禁自检 / 禁同 prompt 复审

## 待办

详见 `__memo__/20260429_架构定稿.md` 的「本轮挂账」章节。
