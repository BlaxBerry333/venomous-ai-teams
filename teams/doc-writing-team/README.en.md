# doc-writing-team

[中文](./README.md) | English | [日本語](./README.ja.md)

## What it is

Forces Claude to **gather evidence before drafting** on doc tasks: collector fetches sources into `sources/`, writer's tool allowlist excludes web access, drafting starts only after you sign off on the outline. **Only produces .md/.mdx** — no code, no build.

## Workflow + features

`/doc-writing-team <topic>` → auto-detect target dir layout → ask about multilang → collector fetches → you confirm sources → outline → you confirm outline → writer drafts.

- **Source traceability**: every fact lands in `sources/` with URL + fetch time; writer's tool allowlist excludes WebFetch/WebSearch — no fact-fabrication
- **Layout-adaptive**: auto-detects pure-docs repo / VitePress·Docusaurus·MkDocs project / general repo
- **Outline-first for complex topics**: nested structure + section bullets shown for approval before drafting
- **Edits stay in conversation**: say "add X / drop Y / rewrite Z" — main thread handles it, no new task
- **Multilang on demand**: defaults to one language; asked once per task

## Roles

| Role | Does | Doesn't |
|---|---|---|
| **collector** | Fetch + summarize → `sources/` | Doesn't draft, doesn't guess, doesn't merge topics |
| **writer** | Draft from confirmed outline + update sidebar/nav | No web access, no code, no deps, no build |

## vs. third-party (data: 2026-05)

| Dimension | doc-writing-team | Mintlify | Docusaurus | Direct ChatGPT/Claude |
|---|:---:|:---:|:---:|:---:|
| Source traceability<br/>(frontmatter sources[]) | ✅ | ❌ | ❌ | ❌ |
| Physical anti-fabrication<br/>(writer has no web tools) | ✅ | ❌<br/>Writing Agent has web access | N/A | ❌ |
| Outline approval gate | ✅ | ❌<br/>generates directly | N/A | ⚠️<br/>only if user asks |
| Multi-lang i18n auto-adapt | ✅<br/>Glob existing | ✅<br/>docs.json | ✅<br/>i18n/ | ❌ |
| Translation structure-preserving<br/>(mdx/frontmatter/code blocks) | ✅<br/>1:1 hard rule | ⚠️<br/>manual<br/>or via Locadex | ⚠️<br/>manual<br/>or via Crowdin | ❌ |
| Platform | Claude Code | SaaS | OSS | Web/API |
| Cost per medium task | $0.30-1.20 | $250/mo+ | free + your own LLM | $0.05-0.20 |

## Usage

### Install/remove

```bash
bash setup.sh   # interactive install / remove + team + target project
```

### Commands

| Command | What |
|---|---|
| `/doc-writing-team <topic>` | Full flow<br/>layout detect → multilang ask → collector → user confirms sources → outline → user confirms outline → writer |
| `/doc-writing-team:翻译 <translation request>` | Single file / Glob batch translate<br/>e.g. `translate docs/intro.md to English`, structure-preserving |

### Installed layout (in your project)

```
<your project>/
├── .claude/
│   ├── commands/
│   │   ├── doc-writing-team.md            # /doc-writing-team entry (full flow)
│   │   └── doc-writing-team/
│   │       └── 翻译.md                    # /doc-writing-team:翻译
│   ├── agents/doc-writing-team/
│   │   ├── collector.md                   # name: doc-writing-team-collector
│   │   └── writer.md                      # name: doc-writing-team-writer
│   ├── hooks/doc-writing-team/
│   │   └── path-guard.sh                  # blocks sub-agent writes to .claude/
│   ├── templates/doc-writing-team/
│   │   ├── source-template.md             # used by collector
│   │   └── article-template.md            # used by writer
│   └── .fragments/doc-writing-team.json   # hook + permissions fragment (merged into settings.json)
│
├── __ai__/
│   └── doc-writing-team/                  # collector's fetched material (preserved when team is removed)
│       └── sources/
│           └── YYYYMMDD_<slug>__N.md
│
└── docs/                                  # writer output (all layouts land in docs/)
    ├── <slug>.md                          # single file (default for short-to-medium docs)
    └── <slug>/                            # multi-file (only when independent sub-topics, each ≥800 words)
        ├── index.md
        └── <chapter>.md
```
