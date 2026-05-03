# web-design-team

[中文](./README.md) | [English](./README.en.md) | 日本語

## 概要

ビジュアル密集型のブランドサイト / ランディング / 公式サイト案件で Claude に **「パラメトリック設計してから実装」** を強制する：分解者は参考サイトを解析（URL がある時だけ走り、無ければゼロから設計）、設計者が design-spec を出し、実行者がプロトタイプを構築、3 つの sub-agent が並列レビュー。**出力は design-spec + プロトタイプのみ、業務データ接続なし**。

## ワークフロー + 特徴

`/web-design-team <要望 + 参考 URL>` → 参考分解（URL があるときだけ走る）→ 設計者が spec + 5 列レポート表を出力 → OK 返信 → 実行者がプロトタイプ作成 → 3 つの sub-agent が並列レビュー → 修正。

- **参考サイトのリバースエンジニアリング**：動効手法 / アセット / 再現難易度を実際のフレームキャプチャから抽出、スクショから推測しない
- **動効パラメータ化**：duration / easing / トリガー / 開始終了状態の 4 点必須、「滑らか」「自然」などの曖昧語は禁止
- **プレースホルダはダウンストリーム前提**：spec §5 に実物仕様 + 置換パスがあるので、ダウンストリーム（web-dev-team / 人間フロントエンド）がそのまま引き継げる
- **本当に独立したレビュー**：再現度 / パフォーマンス / a11y は 3 つの sub-agent が別コンテキストで走る、LLM 自己レビューではない

## ロール

| ロール | 担当 | 担当外 |
|---|---|---|
| **参考拆解者**（分解者） | 参考サイトの技術スタック + アセット + 動効リスト抽出 → refs/ に保存 | 設計しない、コード書かない |
| **设计师**（設計者） | design-spec 出力（分区/コンポーネント/動効パラメータ/アセット/性能予算）+ 5 列レポート表 | コード書かない |
| **执行者**（実行者） | スケルトンコピー + spec 通りに動くプロトタイプ構築（デフォルトは React+Vite+framer-motion 軽装；r3f / gsap / lucide は spec §8 で宣言時のみ追加） | spec 編集禁止、実アセット DL 禁止 |
| **审查员**（レビュアー） | 3 つの sub-agent を並列調停（再現度 / 性能 / a11y） | コード書かない、spec 編集禁止 |

## サードパーティとの比較（データ 2026-05）

| 項目 | web-design-team | v0.dev | Galileo AI | Framer AI |
|---|:---:|:---:|:---:|:---:|
| 参考サイト逆解析 | ✅<br/>WebFetch / Playwright | ❌ | ❌ | ❌ |
| 3D / WebGL プロトタイプ | ✅<br/>r3f + drei | ⚠️<br/>限定的 | ❌ | ⚠️<br/>限定的 |
| パラメトリック動効仕様 | ✅<br/>easing/duration/トリガー | ❌<br/>コードのみ | ❌ | ⚠️ |
| ダウンストリーム移植可 spec | ✅<br/>構造化 md | ❌ | ❌ | ❌<br/>プラットフォームロック |
| プレースホルダアセット一覧 | ✅<br/>実物仕様 + 置換パス | ❌ | ❌ | ❌ |
| 3 つの sub-agent 独立レビュー | ✅<br/>再現度 / 性能 / a11y | ❌ | ❌ | ❌ |
| プラットフォーム | Claude Code | SaaS | SaaS | SaaS |
| 中規模タスク 1 回コスト * | $0.5-2.5 | $20/月～ | $19/月～ | $15/月～ |

\* 推定値。設計者 + 実行者 + 3 つの sub-agent 並列レビュー込み。実コストは動効複雑度・モデル選択・フルパイプライン実行の有無で変動：シンプルなページなら $0.2 まで下がり、重い 3D + 複数修正ラウンドだと $4+ に達することも。

## 使い方

### インストール / 削除

```bash
bash setup.sh   # 対話的: install / remove + team + ターゲットプロジェクト
```

### コマンド

| コマンド | 動作 |
|---|---|
| `/web-design-team <要望>` | フルフロー<br/>分解者（URL あれば）→ 設計者 → ユーザー OK → 実行者 → 3 つの sub-agent レビュー（≤ 3 修正ラウンド） |
| `/web-design-team:参考拆解 <URL>` | 分解者のみ<br/>`refs/<YYYYMMDD_slug>/analysis.md` 出力 |
| `/web-design-team:设计师 <要望>` | 設計者のみ<br/>`designs/<YYYYMMDD_slug>/design-spec.md` 出力 |
| `/web-design-team:执行者 <design-spec パス>` | 実行者のみ<br/>spec 通りプロトタイプ構築、**完了報告前に tsc + vite build 通過必須** |
| `/web-design-team:审查员 <design-spec パス>` | 指定 design をレビュー<br/>≥2 design ある時は引数必須、1 つの時は省略可 |

### インストール後ディレクトリ構造（ターゲットプロジェクト内）

```
<your project>/
├── .claude/
│   ├── commands/
│   │   ├── web-design-team.md            # /web-design-team エントリ（フルフロー調停）
│   │   └── web-design-team/
│   │       ├── 参考拆解.md                # /web-design-team:参考拆解
│   │       ├── 设计师.md                  # /web-design-team:设计师
│   │       ├── 执行者.md                  # /web-design-team:执行者
│   │       └── 审查员.md                  # /web-design-team:审查员（3 つの sub-agent 調停）
│   ├── agents/web-design-team/           # 独立 sub-agent 3 つ
│   │   ├── 审查员-还原度.md
│   │   ├── 审查员-性能.md
│   │   └── 审查员-可访问性.md
│   ├── hooks/web-design-team/            # PreToolUse hook
│   │   └── path-guard.sh                 # sub-agent の .claude/ 書き込みブロック
│   ├── templates/web-design-team/
│   │   ├── analysis-template.md          # 分解者用
│   │   ├── design-spec-template.md       # 設計者用
│   │   └── prototype-skeleton/           # 実行者がコピーする Vite+React テンプレ
│   └── .fragments/web-design-team.json   # hook + permissions 断片（settings.json にマージ）
│
└── __ai__/
    └── web-design-team/                  # 成果物（team 削除時保持）
        ├── refs/<YYYYMMDD_slug>/         # 分解出力
        │   └── analysis.md
        └── designs/<YYYYMMDD_slug>/
            ├── design-spec.md            # 設計者が書いた spec
            └── prototype/                # 実行可能プロトタイプ（npm install && npm run dev）
                ├── README.md             # design 専用説明（実行者が書き換え、テンプレデフォルトではない）
                └── placeholder-todo.md   # §5 プレースホルダ資産チェックリスト、ダウンストリーム引き継ぎ用
```

## ダウンストリーム連携

ダウンストリーム team（web-dev-team / 人間フロントエンド）が design を引き継ぐ際：

1. `designs/<slug>/design-spec.md` を Read：§2 コンポーネント木 / §3 トークン / §4 動効パラメータ / §7 性能予算
2. `designs/<slug>/prototype/README.md` を Read：本 design の用途と起動方法
3. `designs/<slug>/prototype/placeholder-todo.md` を Read：プレースホルダを実物資産に逐次置換しチェック
4. 全項目チェック完了 → プロトタイプは本番投入可能資産にアップグレード；ターゲットプロジェクトのスタックへ移植可能

> **レスポンシブ範囲**：本 team の成果物は 1024+ デスクトップ幅でのビジュアル & インタラクションのみ提示。モバイル対応はダウンストリーム team がターゲットプロジェクトのブレークポイントシステム（Tailwind / MUI / 自社グリッド）に従って実装する。spec §7 `mobile` には降格意図（どの動効/3D を切るか・hero を縦積みするか）が記載されているので参考に。詳細断点はダウンストリーム責任。

## ソフト依存

- **Node.js + npm**：プロトタイプ実行に必要（Vite プロジェクト）
- **Playwright**（**強く推奨**、技術的には任意）：参考分解時にスクロールフレーム + 動効録画を取得。無ければ WebFetch にフォールバックして静的 HTML のみとなり、**スクロール / hover / mousemove 系動効は推測頼り**——分解者の価値の大半が損なわれる。初回 `npx playwright install chromium` を一度走らせるだけ
