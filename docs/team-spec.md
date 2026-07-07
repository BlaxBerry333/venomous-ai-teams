# Team Shared Conventions

English | [中文](./team-spec.zh.md) | [日本語](./team-spec.ja.md)

Mandatory reading before building any team. All teams share these rules. (Promoted from the internal spec v1 finalized 2026-04-29; the git-tracked version is canonical from here on.)

## 1. Directory layout (`teams/<team>/` mirrors installed artifacts 1:1)

```
teams/<team>/
├── README.md                       # Team docs (4 sections: positioning / commands / workflow / removal)
├── .claude/                        # → installed into target project's .claude/
│   ├── commands/<team>/*.md        # Slash commands, Chinese filenames
│   ├── agents/<team>/*.md          # Sub-agents, English kebab-case filenames
│   ├── hooks/<team>/*.sh           # Deterministic validation scripts
│   ├── .fragments/<team>.json      # settings.json fragment (merge source)
│   └── templates/<team>/*          # Optional: team templates
└── __ai__/<team>/                  # → installed into target project's __ai__/<team>/
```

Team removal = `rm -rf .claude/{commands,agents,hooks,templates}/<team>/ .claude/.fragments/<team>.json __ai__/<team>/` (prefer `setup.sh` Remove, which also re-merges settings.json)

## 2. Naming

| Object | Rule | Example |
|---|---|---|
| Slash command filename | Chinese, short | `设计.md` → `/web-dev-team:设计` |
| Team entry command | `commands/<team>.md` triggers `/<team>` (optional) | `commands/web-dev-team.md` → `/web-dev-team` |
| Sub-agent filename | Chinese or English kebab-case | `审查员-逻辑审查.md` or `code-reviewer.md` |
| Sub-agent frontmatter `name` | **English required**, `<team>-<role>` (used for spawn) | `web-dev-team-reviewer-logic` |
| Hook script | English kebab-case, `.sh` | `path-guard.sh` |
| Team name | English kebab-case, `-team` suffix | `web-dev-team` |
| Artifact dir | `__ai__/<team>/` | `__ai__/web-dev-team/specs/` |

## 3. settings.json fragment format (`.fragments/<team>.json`)

```jsonc
{
  "hooks": { ... },
  "permissions": { "allow": [...], "deny": [...] }
}
```

- Only `hooks` + `permissions` allowed; never global keys like `env / theme / model`
- Merged into the target project's settings.json by `scripts/settings.sh` via jq (fragments from multiple teams coexist; these two fields are framework-managed — users keep personal config in settings.local.json)

## 4. Hook contract

- `#!/usr/bin/env bash` + `set -euo pipefail`
- macOS bash 3.2+ compatible (no mapfile / declare -A / `\s\d\w`)
- exit codes (official Claude Code semantics, the **reverse** of Unix convention): `0` pass / **`2` block** (stderr fed back to the LLM) / **`1` non-blocking** (first stderr line shown as a hook error notice)
- stderr = for user/LLM; stdout is parsed as a JSON control structure only on exit 0
- Use `${CLAUDE_PROJECT_DIR}` for paths, never relative paths
- Read only `__ai__/<team>/` and the file being modified; **never read across teams** (`__ai__/<other-team>/`)

## 5. Sub-agent prompt contract

- ≤ 60 lines
- Frontmatter must include: `name` / `description` / `tools` / `model`
- `description` states the **trigger condition** (for hooks / main-loop dispatch), not an introduction
- `tools` minimal set, never wide-open
- Bash under the strictest deny (rm / sudo / curl POST etc.)

## 6. Slash command contract

- ≤ 80 lines
- Frontmatter: one-sentence `description`; `argument-hint` required
- Body is imperative steps, no preamble
- Reference team resources by project-root-relative path `.claude/agents/<team>/xxx.md` (no leading `/`)

## 7. Artifact paths (`__ai__/<team>/`)

- Team-defined substructure, **never write outside the team dir**
- specs/decisions must use the `YYYYMMDD_xxx.md` prefix
- Scratch drafts go in `__ai__/<team>/.scratch/`, not copied by setup.sh

## 8. README.md (required per team)

Fixed four sections: positioning (1 sentence) / commands added after install / typical workflow (≤5 steps) / removal. Trilingual (README.md in English as default).

## Quantitative targets

- Sub-agent prompt ≤ 60 lines
- Top-level CLAUDE.md ≤ 50 lines (injected every turn)
- Simple requests (1-2 file edits): zero sub-agent spawns
