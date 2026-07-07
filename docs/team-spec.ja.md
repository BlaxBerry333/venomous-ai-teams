# Team 共通規約

[English](./team-spec.md) | [中文](./team-spec.zh.md) | 日本語

いかなる team を書く前にも必読。全 team 共通の規約。(2026-04-29 確定の内部規約 v1 から昇格。以降は git 管理版を正とする。)

## 1. ディレクトリ構造(`teams/<team>/` はインストール成果物と 1:1 対応)

```
teams/<team>/
├── README.md                       # team 説明(4 節:位置づけ/コマンド/ワークフロー/削除)
├── .claude/                        # → 対象プロジェクトの .claude/ にインストール
│   ├── commands/<team>/*.md        # slash command,ファイル名は中国語
│   ├── agents/<team>/*.md          # sub-agent,ファイル名は英語 kebab-case
│   ├── hooks/<team>/*.sh           # 決定論的検証スクリプト
│   ├── .fragments/<team>.json      # settings.json 断片(マージ元)
│   └── templates/<team>/*          # 任意:team テンプレート
└── __ai__/<team>/                  # → 対象プロジェクトの __ai__/<team>/ にインストール
```

team 削除 = `rm -rf .claude/{commands,agents,hooks,templates}/<team>/ .claude/.fragments/<team>.json __ai__/<team>/`(`setup.sh` の Remove 推奨。settings.json も再マージされる)

## 2. 命名規約

| 対象 | ルール | 例 |
|---|---|---|
| slash command ファイル名 | 中国語,短く | `设计.md` → `/web-dev-team:设计` |
| team エントリコマンド | `commands/<team>.md` が `/<team>` を起動(任意)| `commands/web-dev-team.md` → `/web-dev-team` |
| sub-agent ファイル名 | 中国語 or 英語 kebab-case | `审查员-逻辑审查.md` / `code-reviewer.md` |
| sub-agent frontmatter `name` | **英語必須** `<team>-<role>`(spawn 用) | `web-dev-team-reviewer-logic` |
| hook スクリプト | 英語 kebab-case,`.sh` | `path-guard.sh` |
| team 名 | 英語 kebab-case,`-team` 接尾辞 | `web-dev-team` |
| 成果物ディレクトリ | `__ai__/<team>/` | `__ai__/web-dev-team/specs/` |

## 3. settings.json 断片フォーマット(`.fragments/<team>.json`)

```jsonc
{
  "hooks": { ... },
  "permissions": { "allow": [...], "deny": [...] }
}
```

- `hooks` + `permissions` のみ許可。`env / theme / model` 等のグローバル項目は禁止
- `scripts/settings.sh` が jq で対象プロジェクトの settings.json にマージ(複数 team の断片が共存。この 2 フィールドはフレームワーク管理——個人設定は settings.local.json へ)

## 4. hook 契約

- `#!/usr/bin/env bash` + `set -euo pipefail`
- macOS bash 3.2+ 互換(mapfile / declare -A / `\s\d\w` 禁止)
- exit(Claude Code 公式セマンティクス。Unix 慣例と**逆**):`0` 通過 / **`2` ブロック**(stderr が LLM へ)/ **`1` 非ブロック**(stderr 先頭行が hook error notice として表示)
- stderr = ユーザー/LLM 向け;stdout は exit 0 時のみ JSON 制御構造として解析
- パスは `${CLAUDE_PROJECT_DIR}`。相対パス禁止
- 読むのは `__ai__/<team>/` と変更対象ファイルのみ;**team 跨ぎの読み取り禁止**(`__ai__/<他 team>/`)

## 5. sub-agent prompt 契約

- ≤ 60 行
- frontmatter 必須:`name` / `description` / `tools` / `model`
- `description` は**起動条件**を書く(hook / メイン対話の判断用)。紹介文ではない
- `tools` は最小集合。全開禁止
- Bash は最も厳しい deny(rm / sudo / curl POST 等)

## 6. slash command 契約

- ≤ 80 行
- frontmatter:`description` 一文;`argument-hint` 必須
- 本文は命令形の手順のみ。前置き禁止
- team リソース参照はプロジェクトルート相対パス `.claude/agents/<team>/xxx.md`(先頭 `/` なし)

## 7. 成果物パス(`__ai__/<team>/`)

- team 独自のサブ構造。**team ディレクトリ外への書き込み禁止**
- specs/decisions は `YYYYMMDD_xxx.md` プレフィックス強制
- 一時ドラフトは `__ai__/<team>/.scratch/`。setup.sh はコピーしない

## 8. README.md(各 team 必須)

固定 4 節:位置づけ(1 文)/ インストール後に増えるコマンド / 典型ワークフロー(≤5 手順)/ 削除方法。三言語(README.md は英語がデフォルト)。

## 定量目標

- sub-agent prompt ≤ 60 行
- トップレベル CLAUDE.md ≤ 50 行(毎ターン固定注入)
- 単純な要望(1-2 ファイル変更)は sub-agent ゼロ
