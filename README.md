# Venomous AI Teams

基于 Claude Code 的多角色 AI 协作框架。

## 快速开始

```bash
# 1. 拉框架
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams

# 2. 交互式装到目标项目
bash setup.sh

# 3. 建议把框架产物加进 .gitignore
cd <your_project>
printf '\n.claude/\n__ai__/\n' >> .gitignore
```

> 一次装一个 team。
>
> 切换 team 时候请重跑 `setup.sh`。

<br/>

## 内置团队

| 团队                                       | 说明                                                       |
| ------------------------------------------ | ---------------------------------------------------------- |
| [dev-team](teams/dev-team/README.md)       | 5 角色开发流程：设计 → 验证 → 开发 → 审查 → 测试           |
| [design-team](teams/design-team/README.md) | 4 角色设计流程：设计规格 → 验证 → HTML+CSS 原型 → 设计审查 |
| [docs-team](teams/docs-team/README.md)     | 领域专家驱动的知识库文档工作流                             |

<br/>

## License

MIT
