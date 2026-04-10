# Venomous AI Teams

基于 Claude Code 的多角色 AI 协作框架。复制到项目即可使用。

## 快速开始

```bash
bash setup.sh
```

交互式安装向导：选择团队 → 输入目标路径 → 自动合并。支持多团队同时安装，自动解决 hooks、settings.json、CLAUDE.md 的冲突。

> 也可手动复制单个团队: `cp -r teams/dev-team/.claude your-project/ && cp -r teams/dev-team/__ai__ your-project/`

## 内置团队

| 团队                                       | 说明                                                       |
| ------------------------------------------ | ---------------------------------------------------------- |
| [dev-team](teams/dev-team/README.md)       | 5 角色开发流程：设计 → 验证 → 开发 → 审查 → 测试           |
| [design-team](teams/design-team/README.md) | 4 角色设计流程：设计规格 → 验证 → HTML+CSS 原型 → 设计审查 |
| [docs-team](teams/docs-team/README.md)     | 领域专家驱动的知识库文档工作流（当前：编程专家）           |

## License

MIT
