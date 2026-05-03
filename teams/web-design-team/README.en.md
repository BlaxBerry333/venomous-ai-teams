# web-design-team

[中文](./README.md) | English | [日本語](./README.ja.md)

## What it is

Forces Claude on visually-dense brand sites / landing pages / official sites to **parametrize the design before building**: a dissector scrapes the reference (only when a URL is given — otherwise designs from scratch), a designer emits the design-spec, an executor scaffolds a runnable prototype, 3 sub-agents review in parallel. **Output is design-spec + prototype only — no business data wiring.**

## Workflow + features

`/web-design-team <request + reference URL>` → dissect reference (only when a URL is given) → designer emits spec + 5-column report table → you reply OK → executor scaffolds prototype → 3 sub-agents review in parallel → fixes.

- **Reference reverse-engineering**: animation techniques / assets / replication difficulty are pulled from real frame captures, not guessed from screenshots
- **Parametric animation**: duration / easing / trigger / start-end states are mandatory — fluff like "smooth and natural" is banned
- **Downstream-friendly placeholders**: spec §5 gives real-asset specs + replacement paths so downstream (web-dev-team / human frontend) plugs straight in
- **Truly independent review**: fidelity / performance / a11y run in 3 separate sub-agent contexts, not LLM self-review

## Roles

| Role | Does | Doesn't do |
|---|---|---|
| **参考拆解者** (Dissector) | Scrapes reference: tech stack + assets + animation list → writes refs/ | No design, no code |
| **设计师** (Designer) | Emits design-spec (sections / components / params / assets / perf budget) + 5-col report table | No code |
| **执行者** (Executor) | Copies skeleton + builds runnable prototype (default lean React+Vite+framer-motion; r3f / gsap / lucide added on demand when spec §8 declares them) | No spec edits, no real-asset downloads |
| **审查员** (Reviewer) | Orchestrates 3 sub-agents in parallel (fidelity / performance / a11y) | No code, no spec edits |

## vs. third-party (data: 2026-05)

| Dimension | web-design-team | v0.dev | Galileo AI | Framer AI |
|---|:---:|:---:|:---:|:---:|
| Reference reverse-engineering | ✅<br/>WebFetch / Playwright | ❌ | ❌ | ❌ |
| 3D / WebGL prototype | ✅<br/>r3f + drei | ⚠️<br/>limited | ❌ | ⚠️<br/>limited |
| Parametric animation spec | ✅<br/>easing/duration/trigger | ❌<br/>code-only | ❌ | ⚠️ |
| Downstream-portable spec | ✅<br/>structured md | ❌ | ❌ | ❌<br/>platform-locked |
| Placeholder asset list | ✅<br/>real specs + replace paths | ❌ | ❌ | ❌ |
| 3 sub-agents independent review | ✅<br/>fidelity / perf / a11y | ❌ | ❌ | ❌ |
| Platform | Claude Code | SaaS | SaaS | SaaS |
| Cost per medium task * | $0.5-2.5 | $20/mo+ | $19/mo+ | $15/mo+ |

\* Estimate. Covers designer + executor + 3 sub-agents in parallel. Actual cost depends on motion complexity, model choice, and whether the full pipeline runs — simple pages may go as low as $0.2; heavy 3D with multiple fix rounds can hit $4+.

## Usage

### Install / Remove

```bash
bash setup.sh   # interactive: install / remove + team + target project
```

### Commands

| Command | What it does |
|---|---|
| `/web-design-team <request>` | Full flow<br/>dissector (if URL) → designer → user OK → executor → 3 sub-agents review (≤ 3 fix rounds) |
| `/web-design-team:参考拆解 <URL>` | Dissector only<br/>emits `refs/<YYYYMMDD_slug>/analysis.md` |
| `/web-design-team:设计师 <request>` | Designer only<br/>emits `designs/<YYYYMMDD_slug>/design-spec.md` |
| `/web-design-team:执行者 <design-spec path>` | Executor only<br/>scaffolds prototype per spec; **must pass tsc + vite build before reporting done** |
| `/web-design-team:审查员 <design-spec path>` | Reviews specified design<br/>required when ≥2 designs exist; optional when only 1 |

### Layout after install (in your project)

```
<your project>/
├── .claude/
│   ├── commands/
│   │   ├── web-design-team.md            # /web-design-team entry (full-flow orchestrator)
│   │   └── web-design-team/
│   │       ├── 参考拆解.md                # /web-design-team:参考拆解
│   │       ├── 设计师.md                  # /web-design-team:设计师
│   │       ├── 执行者.md                  # /web-design-team:执行者
│   │       └── 审查员.md                  # /web-design-team:审查员 (orchestrates 3 sub-agents)
│   ├── agents/web-design-team/           # Three independent sub-agents
│   │   ├── 审查员-还原度.md
│   │   ├── 审查员-性能.md
│   │   └── 审查员-可访问性.md
│   ├── hooks/web-design-team/            # PreToolUse hook
│   │   └── path-guard.sh                 # Blocks sub-agent writes to .claude/
│   ├── templates/web-design-team/
│   │   ├── analysis-template.md          # for dissector
│   │   ├── design-spec-template.md       # for designer
│   │   └── prototype-skeleton/           # Vite+React skeleton copied by executor
│   └── .fragments/web-design-team.json   # hook + permissions fragment (merged into settings.json)
│
└── __ai__/
    └── web-design-team/                  # Your artifacts (preserved on team removal)
        ├── refs/<YYYYMMDD_slug>/         # Dissection output
        │   └── analysis.md
        └── designs/<YYYYMMDD_slug>/
            ├── design-spec.md            # Spec written by designer
            └── prototype/                # Runnable prototype (npm install && npm run dev)
                ├── README.md             # design-specific README (rewritten by executor, not template default)
                └── placeholder-todo.md   # §5 placeholder asset checklist for downstream handoff
```

## Downstream handoff

Downstream teams (web-dev-team / human frontends) picking up a design:

1. Read `designs/<slug>/design-spec.md` for §2 component tree / §3 tokens / §4 motion params / §7 perf budget
2. Read `designs/<slug>/prototype/README.md` for what this design does + how to run
3. Read `designs/<slug>/prototype/placeholder-todo.md` and check items off as you swap placeholders for real assets
4. Once all items checked → prototype is upgraded to production-ready assets; can be migrated to your target project stack

> **Responsive scope**: This team's outputs only demo visuals & interactions at 1024+ desktop widths. Mobile responsive adaptation is the downstream team's job, against the target project's breakpoint system (Tailwind / MUI / your own grid). Spec §7 `mobile` notes the intent (which animations/3D to drop or simplify, whether hero stacks vertically) — breakpoint details are left to downstream.

## Soft dependencies

- **Node.js + npm**: required to run the prototype (Vite project)
- **Playwright** (**strongly recommended**, technically optional): captures scroll frames + animation recording during dissection. Without it, the dissector falls back to WebFetch with static HTML only — **scroll / hover / mousemove animations have to be guessed**, gutting most of the dissector's value. One-time setup: `npx playwright install chromium`
