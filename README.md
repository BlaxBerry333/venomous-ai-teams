# Venomous AI Teams

基于 Claude Code 的多角色 AI 协作框架。复制到项目即可使用。

## 快速开始

```bash
cp -r teams/dev-team/.claude   your-project/
cp -r teams/dev-team/__ai__    your-project/

cd your-project && claude
# 输入: /角色命令 你的需求描述
```

## 内置团队

| 团队                                   | 说明                                                       |
| -------------------------------------- | ---------------------------------------------------------- |
| [dev-team](teams/dev-team/README.md)   | 5 角色驱动的完整开发流程：设计 → 验证 → 开发 → 审查 → 测试 |
| [docs-team](teams/docs-team/README.md) | 领域专家驱动的知识库文档工作流（当前：编程专家）           |

## License

MIT
