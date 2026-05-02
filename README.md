# venomous-ai-teams

中文 | [English](./README.en.md) | [日本語](./README.ja.md)

把 Claude Code 的多角色 + spec 流程 + 反幻觉审查打包成一键安装的 team。<br/>
装哪个 team，主对话就具备哪个领域的"想-写-审"流水线。

## 可用 team

| Team | 干啥 | 文档 |
|---|---|---|
| **web-dev-team** | web 开发 | [中文](teams/web-dev-team/README.md) · [English](teams/web-dev-team/README.en.md) · [日本語](teams/web-dev-team/README.ja.md) |
| **doc-writing-team** | 带来源的 markdown 文档写作 | [中文](teams/doc-writing-team/README.md) · [English](teams/doc-writing-team/README.en.md) · [日本語](teams/doc-writing-team/README.ja.md) |

## 安装

### 前置依赖

| 依赖 | 用途 | macOS | Linux |
|---|---|---|---|
| bash ≥ 3.2 | setup.sh / hooks | 系统自带 | 系统自带 |
| jq | settings.json 合成 | `brew install jq` | `apt install jq` / `dnf install jq` |
| gum | 交互式 UI | `brew install gum` | [charmbracelet/gum](https://github.com/charmbracelet/gum#installation) |
| git | hook 数文件改动 | 系统自带 | 系统自带 |
| Claude Code | 跑装好的 team | [安装文档](https://claude.com/claude-code) | 同 |

Windows 用户请用 WSL2，原生 Windows 不支持。

### 安装步骤

```bash
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams
bash setup.sh   # 交互式：install / reinstall / remove + 选 team + 选目标项目
```

装好后在你的项目里跑 team 命令（如 `/web-dev-team <需求>`）。命令详情见上表中的 team 文档。

## 贡献

想给本仓库贡献代码（开发新 team / 改进框架）？见 [CONTRIBUTING.md](./CONTRIBUTING.md)。
