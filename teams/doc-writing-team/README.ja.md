# doc-writing-team

[English](./README.md) | [中文](./README.zh.md) | 日本語

## 概要

Claude にドキュメントタスクで **根拠を集めてから書かせる**：collector が素材を `sources/` に収集、writer のツール許可リストはネット接続を除外、ユーザーがアウトラインを承認してから執筆開始。**.md/.mdx のみ生成** — コードや build には触れない。

## ワークフロー + 特徴

`/doc-writing-team <テーマ>` → ディレクトリ形態を自動判定 → 多言語の確認 → collector 収集 → 素材確認 → アウトライン → アウトライン確認 → writer 執筆。

- **出典トレース可**：各事実は `sources/` に URL + 取得時刻付きで保存；writer のツール許可リストは WebFetch/WebSearch を除外し、執筆中のでっち上げを根本から防ぐ
- **形態自動判定**：純ドキュメントリポ / VitePress·Docusaurus·MkDocs プロジェクト / 一般リポを識別
- **複雑テーマはアウトライン先行**：ネスト構造 + 各章要点を提示し承認を待ってから執筆
- **追加・調整は会話内で**："X 追加 / Y 削除 / Z 書き直し" を本対話で直接処理、新タスク不要
- **多言語は要求ベース**：デフォルトは単一言語、タスク開始時に一度だけ確認

## ロール

| ロール | 役割 | やらないこと |
|---|---|---|
| **collector** | 取得 + 要約 → `sources/` | 最終ドキュメントを書かない・推測しない・テーマ混合しない |
| **writer** | 確認済みアウトラインで執筆 + sidebar/nav 更新 | ネット非接続・コード書かない・依存追加しない・build しない |

## サードパーティとの比較（データ 2026-05）

| 項目 | doc-writing-team | Mintlify | Docusaurus | 直接 ChatGPT/Claude |
|---|:---:|:---:|:---:|:---:|
| 出典トレース可<br/>（frontmatter sources[]） | ✅ | ❌ | ❌ | ❌ |
| 物理的な反幻覚<br/>（writer はネット不可） | ✅ | ❌<br/>Writing Agent はネット可 | N/A | ❌ |
| アウトライン承認ゲート | ✅ | ❌<br/>直接生成 | N/A | ⚠️<br/>ユーザー次第 |
| 多言語 i18n 自動対応 | ✅<br/>既存 layout 観察 | ✅<br/>docs.json | ✅<br/>i18n/ | ❌ |
| 翻訳の構造保持<br/>（mdx/frontmatter/コードブロック） | ✅<br/>1:1 ハード規則 | ⚠️<br/>手動<br/>または Locadex | ⚠️<br/>手動<br/>または Crowdin | ❌ |
| プラットフォーム | Claude Code | SaaS | OSS | Web/API |
| 中規模タスク 1 回あたりのコスト | $0.30-1.20 | $250/月〜 | 無料 + 自前 LLM | $0.05-0.20 |

## 使い方

### インストール / 削除

```bash
bash setup.sh   # 対話式 install / remove + team + 対象プロジェクト選択
```

### コマンド

| コマンド | 内容 |
|---|---|
| `/doc-writing-team <テーマ>` | フルフロー<br/>形態判定 → 多言語確認 → collector → 素材確認 → アウトライン → アウトライン確認 → writer |
| `/doc-writing-team:翻译 <翻訳要望>` | 単一ファイル / Glob 一括翻訳<br/>例：`docs/intro.md を英語に翻訳`、構造保持 |

### インストール後の構成（対象プロジェクト内）

```
<対象プロジェクト>/
├── .claude/
│   ├── commands/
│   │   ├── doc-writing-team.md            # /doc-writing-team エントリ（フルフロー）
│   │   └── doc-writing-team/
│   │       └── 翻译.md                    # /doc-writing-team:翻译
│   ├── agents/doc-writing-team/
│   │   ├── collector.md                   # name: doc-writing-team-collector
│   │   └── writer.md                      # name: doc-writing-team-writer
│   ├── hooks/doc-writing-team/
│   │   └── path-guard.sh                  # sub-agent の .claude/ への書き込みを遮断
│   ├── templates/doc-writing-team/
│   │   ├── source-template.md             # collector 用
│   │   └── article-template.md            # writer 用
│   └── .fragments/doc-writing-team.json   # hook + permissions 片（settings.json にマージ）
│
├── __ai__/
│   └── doc-writing-team/                  # collector の収集素材（team 削除時も保持）
│       └── sources/
│           └── YYYYMMDD_<slug>__N.md
│
└── docs/                                  # writer 出力（全形態とも docs/ に統一）
    ├── <slug>.md                          # 単一ファイル（短〜中篇デフォルト）
    └── <slug>/                            # 複数ファイル（独立サブテーマかつ各 ≥800 字の場合のみ）
        ├── index.md
        └── <chapter>.md
```
