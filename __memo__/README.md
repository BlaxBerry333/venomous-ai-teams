# Repo Dev Memory

[中文](./README.zh.md) | English | [日本語](./README.ja.md)

Cross-session developer memory. New sessions resume context by reading here + `git log`, not chat history.

## File naming

- `YYYYMMDD_短い英語または中文描述.md`, e.g. `20260429_架构定稿.md`

## Writing discipline

- Length-free (not in LLM context, no token cost), but no fluff
- Required frontmatter `status:` (Chinese, no quotes), 4 values:
  - `进行中` — has open todos; **SessionStart hook auto-injects unchecked `- [ ]` items into the conversation**
  - `已定稿` — design doc finalized, rules set, has lasting reference value (e.g. architecture lock, shared conventions)
  - `已完结` — one-off event done (e.g. a specific stumble, a specific review)
  - `暂存` — intentionally parked, waiting for real-world pain to decide (e.g. "deferred features list")
- Only write what's **unrecoverable without this memo**: architecture decisions, stumble lessons, judgment basis
- Don't write what `git log` can answer; write **why**
- Lists + short sentences, no prose

## Structure

No hard template. One opening line stating why this memo exists; middle sections free-form; for open todos use `## 本轮挂账` + `- [ ]` / `- [x]` checkboxes.
