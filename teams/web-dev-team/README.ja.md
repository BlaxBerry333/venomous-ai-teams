# web-dev-team

[中文](./README.md) | [English](./README.en.md) | 日本語

## 概要

Claude に web 開発タスクで**書く前にしっかり考えさせる**：spec を書く、選定理由を提示する、独立 sub-agent でレビューする。

## サードパーティとの比較

| 項目 | web-dev-team | BMad Method | Spec Kit | Claude Skills |
|---|:---:|:---:|:---:|:---:|
| Spec ループ | ✅ | ✅ | ✅ | ❌ |
| 真に独立した sub-agent レビュー | ✅<br/>3 観点直交 | ⚠️<br/>同一セッション内ロール相互レビュー | ❌ | ❌ |
| Hook ガード（exit 2 で実ブロック） | ✅ | ❌ | ❌ | ❌ |
| 行数ハード制限（prompt 肥大化防止） | ✅<br/>≤50/35/60/80 | ❌ | ❌ | N/A |
| 「選定」プレフィックスで理由を強制 | ✅ | ❌ | ❌ | ❌ |
| マルチ team 共存 | ✅<br/>名前空間分離 | ❌ | ❌ | ⚠️ |
| プラットフォーム | Claude Code | 汎用 | 汎用 | Claude |
| 中規模タスク 1 回あたりのコスト | $0.35-1.75 | $1-10 | 変動 | $0.01-0.1 |

## ワークフロー + 特徴

`/web-dev-team <要望>` → アーキテクトが spec とレポート表を出力 → OK と返信 → 実行者がコード変更 → 3 レビュアーが並列レビュー → 修正 → 完了。

- **選定理由を強制**：`選定：` プレフィックスは web 知識ベースの理由を 1 行必須
- **真の独立レビュー**：3 sub-agent が独立コンテキストで実行、LLM 自己レビューではない
- **全工程トレース可能**：spec / レポート表 / レビュー所見すべて永続化
- **小規模要望はバイパス**：typo は直接実行、曖昧な要望は逆質問、フルフロー無駄遣いなし

## 使い方

### インストール / 削除

```bash
bash setup.sh   # インタラクティブ：install / remove + team + 対象プロジェクトを選択
```

### コマンド

| コマンド | 内容 |
|---|---|
| `/web-dev-team <要望>` | フルフロー<br/>アーキテクト → ユーザー確認 → 実行者 → 3 レビュアー（≤ 3 修正ラウンド） |
| `/web-dev-team:架构者 <要望>` | アーキテクトのみ実行<br/>`/__ai__/web-dev-team/specs/YYYYMMDD_<slug>.md` を出力 |
| `/web-dev-team:执行者 <spec パスまたは生の要望>` | 実行者のみ実行<br/>spec に従ってコード変更 |
| `/web-dev-team:审查员` | 引数なし<br/>デフォルトで未コミット git diff をレビュー |
| `/web-dev-team:审查员 <パスまたは範囲>` | 引数あり<br/>指定したファイル / ディレクトリ / git ref をレビュー |

### インストール後のディレクトリ構成（あなたのプロジェクト内）

```
.claude/
├── commands/
│   ├── web-dev-team.md              # /web-dev-team エントリ（フルフロー調停）
│   └── web-dev-team/
│       ├── 架构者.md                # /web-dev-team:架构者
│       ├── 执行者.md                # /web-dev-team:执行者
│       └── 审查员.md                # /web-dev-team:审查员（3 sub-agent を調停）
├── agents/web-dev-team/             # 3 つの独立 sub-agent
│   ├── 审查员-逻辑审查.md
│   ├── 审查员-现有影响审查.md
│   └── 审查员-需求复审.md
├── hooks/web-dev-team/              # PreToolUse hook
│   ├── path-guard.sh                # .claude/ と他 team ディレクトリへの書き込みをブロック
│   └── spec-required.sh             # 複数ファイル変更時に spec なしなら警告
├── templates/web-dev-team/
│   └── spec-template.md             # spec 7 セクションテンプレート
└── .fragments/web-dev-team.json     # hooks + permissions フラグメント（settings.json に合成）

__ai__/web-dev-team/                 # あなたの成果物（team 削除時も保持）
└── specs/
    └── YYYYMMDD_<slug>.md           # アーキテクトが書いた spec
```
