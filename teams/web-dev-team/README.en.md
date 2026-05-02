# web-dev-team

[中文](./README.md) | English | [日本語](./README.ja.md)

## What it is

Forces Claude to **think before writing** on full-stack web tasks: architect owns full-stack decisions, executor fills in implementation, independent sub-agents review.

## Workflow + features

`/web-dev-team <request>` → architect emits spec + report table → you reply OK → executor codes → 3 reviewers run in parallel → fixes → done.

- **Forced selection rationale**: `Selection:` prefix must carry one-line web-knowledge justification
- **Truly independent review**: 3 sub-agents in separate contexts, not LLM self-review
- **End-to-end traceability**: spec / report table / review findings all persisted
- **Small requests bypass**: typos go direct, vague requests get questioned — no full-flow burn

## Roles

| Role | Does | Doesn't do |
|---|---|---|
| **架构者** (Architect) | Full-stack decisions → emits spec + 5-column report table | No code |
| **执行者** (Executor) | Fills in implementation per spec → modifies code | No spec edits, no architectural decisions |
| **审查员** (Reviewer) | Orchestrates 3 sub-agents on orthogonal aspectsin independent contexts | No code, no spec edits |

## vs. third-party (data: 2026-05)

| Dimension | web-dev-team | BMad Method | Spec Kit | Claude Skills |
|---|:---:|:---:|:---:|:---:|
| Spec loop | ✅ | ✅ | ✅ | ❌ |
| Truly independent sub-agent review | ✅<br/>3 orthogonal aspects | ⚠️<br/>in-session persona | ⚠️<br/>community ext required | ❌ |
| Hook guard<br/>(exit 2 real block) | ✅ | ❌ | ⚠️<br/>ext required | ❌ |
| Hard line limits<br/>(anti prompt-bloat) | ✅ | ❌ | ❌ | N/A |
| `Selection:` forces rationale | ✅ | ❌ | ⚠️<br/>indirect | ❌ |
| Multi-team coexistence | ✅<br/>namespace-isolated | ❌ | ❌ | ⚠️<br/>org-level |
| Platform | Claude Code | multi-IDE | multi-platform | Claude product line |
| Cost per medium task | $0.35-1.75 | $1-10 | varies | $0.01-0.1 |

## Usage

### Install / Remove

```bash
bash setup.sh   # interactive: install / remove + team + target project
```

### Commands

| Command | What it does |
|---|---|
| `/web-dev-team <request>` | Full flow<br/>architect → user OK → executor → 3 reviewers (≤ 3 fix rounds) |
| `/web-dev-team:架构者 <request>` | Architect only<br/>emits `/__ai__/web-dev-team/specs/YYYYMMDD_<slug>.md` |
| `/web-dev-team:执行者 <spec path or raw request>` | Executor only<br/>codes per spec |
| `/web-dev-team:审查员` | No args<br/>defaults to reviewing uncommitted git diff |
| `/web-dev-team:审查员 <path or scope>` | With args<br/>reviews given file / dir / git ref |

### Layout after install (in your project)

```
<your project>/
├── .claude/
│   ├── commands/
│   │   ├── web-dev-team.md              # /web-dev-team entry (full-flow orchestrator)
│   │   └── web-dev-team/
│   │       ├── 架构者.md                # /web-dev-team:架构者
│   │       ├── 执行者.md                # /web-dev-team:执行者
│   │       └── 审查员.md                # /web-dev-team:审查员 (orchestrates 3 sub-agents)
│   ├── agents/web-dev-team/             # Three independent sub-agents
│   │   ├── 审查员-逻辑审查.md
│   │   ├── 审查员-现有影响审查.md
│   │   └── 审查员-需求复审.md
│   ├── hooks/web-dev-team/              # PreToolUse hooks
│   │   ├── path-guard.sh                # Blocks sub-agent writes to .claude/
│   │   └── spec-required.sh             # Warns on multi-file changes without a spec
│   ├── templates/web-dev-team/
│   │   └── spec-template.md             # Spec 8-section template (runtime-topology section is conditional)
│   └── .fragments/web-dev-team.json     # hooks + permissions fragment (merged into settings.json)
│
└── __ai__/
    └── web-dev-team/                    # Your artifacts (preserved on team removal)
        └── specs/
            └── YYYYMMDD_<slug>.md       # Specs written by the architect
```
