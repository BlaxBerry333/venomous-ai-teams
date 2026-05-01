# Contributing

[中文](./CONTRIBUTING.md) | English | [日本語](./CONTRIBUTING.ja.md)

## Getting started

```bash
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams

# Required reading
cat .claude/CLAUDE.md           # Framework dev rules (≤ 40-line hard limit)
cat __memo__/README.md          # Cross-session memory mechanism
```

## Repo layout

```
venomous-ai-teams/
├── setup.sh                    # Install entry (interactive)
├── scripts/                    # setup.sh modules
│   ├── install.sh
│   ├── remove.sh
│   ├── settings.sh             # fragments → settings.json merger
│   ├── platform.sh             # Env checks (bash / jq / gum)
│   ├── safety.sh               # Path safety
│   ├── teams.sh                # Team registry
│   └── ui.sh                   # gum interactive UI
├── teams/                      # Each team pack (artifacts installed into user projects)
│   └── <team>/
│       ├── README.md           # Team docs (4 sections: positioning / commands / workflow / removal)
│       ├── README.en.md
│       ├── README.ja.md
│       └── .claude/            # Mirrored 1:1 into user's .claude/
│           ├── commands/<team>/        # Slash commands
│           ├── agents/<team>/          # Independent sub-agents
│           ├── hooks/<team>/           # bash hook scripts
│           ├── templates/<team>/       # Template files
│           └── .fragments/<team>.json  # hook + permissions fragment (merged into settings.json)
├── .claude/                    # This repo's own Claude Code config (for framework dev, not installed to users)
│   ├── CLAUDE.md               # Framework dev rules (≤ 40-line hard limit)
│   ├── settings.json
│   ├── agents/
│   │   └── 开发审查员.md       # Adversarial review sub-agent (must spawn when developing new teams; distinct from team-product reviewers)
│   └── hooks/
│       └── load-memo.sh        # SessionStart injection of `status: 进行中` memo todos
├── __memo__/                   # Cross-session architecture decisions / lessons (gitignored except README)
│   ├── README.md               # Memo writing conventions
│   └── YYYYMMDD_xxx.md         # Individual memos (developer-local)
└── __playground__/             # Team test ground (fake app + generated specs, gitignored)
```

## Minimum flow to build a new team

1. Read `__memo__/20260429_team公共规范.md` (shared conventions, hard rules)
2. Mirror the `.claude/` structure under `teams/<your-team>/`
3. Write prompts under hard line limits (architect ≤ 50 / executor ≤ 35 / sub-agent ≤ 60 / slash command ≤ 80)
4. Write `.fragments/<team>.json` (hook + permissions fragment)
5. Live test: `bash setup.sh` install to `__playground__/<fake-app>/` and run real scenarios
6. Before declaring done, spawn `.claude/agents/开发审查员.md` — at least 2 independent instances must report zero findings

## Key constraints

- Editing `.claude/{agents,commands,hooks}/`, `teams/*/.claude/{agents,commands,hooks,settings.json}`, or `setup.sh` → MUST spawn 开发审查员 (see `.claude/CLAUDE.md`)
- Don't edit `__memo__/` files marked `status: 已定稿` (unless they're actually wrong)
- Commits must NOT include `Co-Authored-By: Claude` or other AI signatures
- bash scripts must be compatible with macOS bash 3.2+ (no `mapfile` / `declare -A` / `\s\d\w` etc.)

See `.claude/CLAUDE.md` for details.
