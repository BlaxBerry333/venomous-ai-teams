# venomous-ai-teams

[中文](./README.md) | English | [日本語](./README.ja.md)

Packages Claude Code's multi-role + spec flow + anti-hallucination review into one-install teams.<br/>
Install a team, and your main conversation gains that domain's "think → write → review" pipeline.

## Available teams

| Team | What it does | Docs |
|---|---|---|
| **web-dev-team** | Web dev | [中文](teams/web-dev-team/README.md) · [English](teams/web-dev-team/README.en.md) · [日本語](teams/web-dev-team/README.ja.md) |
| **doc-writing-team** | Sourced markdown doc writing | [中文](teams/doc-writing-team/README.md) · [English](teams/doc-writing-team/README.en.md) · [日本語](teams/doc-writing-team/README.ja.md) |
| **web-design-team** | Visually-dense brand / landing / official-site design-spec + runnable prototype | [中文](teams/web-design-team/README.md) · [English](teams/web-design-team/README.en.md) · [日本語](teams/web-design-team/README.ja.md) |

## Install

### Prerequisites

| Dependency | Purpose | macOS | Linux |
|---|---|---|---|
| bash ≥ 3.2 | setup.sh / hooks | built-in | built-in |
| jq | settings.json merging | `brew install jq` | `apt install jq` / `dnf install jq` |
| gum | interactive UI | `brew install gum` | [charmbracelet/gum](https://github.com/charmbracelet/gum#installation) |
| git | hook counts changed files | built-in | built-in |
| Claude Code | runs the installed team | [docs](https://claude.com/claude-code) | same |

Windows: use WSL2. Native Windows is not supported.

### Steps

```bash
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams
bash setup.sh   # interactive: install / reinstall / remove + pick team + pick target project
```

After install, run team commands inside your project (e.g. `/web-dev-team <request>`). See the team docs above for command details.

## Contributing

Want to contribute (build a new team / improve the framework)? See [CONTRIBUTING.en.md](./CONTRIBUTING.en.md).
