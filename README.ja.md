# venomous-ai-teams

[中文](./README.md) | [English](./README.en.md) | 日本語

Claude Code のマルチロール + spec フロー + 反幻覚レビューを 1 コマンドでインストール可能な team にパッケージ化。<br/>
team を入れると、メイン対話にその領域の「考える → 書く → 審査」パイプラインが入る。

## サードパーティとの比較

| 項目 | web-dev-team | BMad Method | Spec Kit | Claude Skills |
|---|:---:|:---:|:---:|:---:|
| Spec ループ | ✅ | ✅ | ✅ | ❌ |
| 真に独立した sub-agent レビュー | ✅<br/>3 観点直交 | ⚠️<br/>同一セッション内ロール相互レビュー | ❌ | ❌ |
| Hook ガード（exit 2 で実ブロック） | ✅ | ❌ | ❌ | ❌ |
| 行数ハード制限（prompt 肥大化防止） | ✅ | ❌ | ❌ | N/A |
| 「選定」プレフィックスで理由を強制 | ✅ | ❌ | ❌ | ❌ |
| マルチ team 共存 | ✅<br/>名前空間分離 | ❌ | ❌ | ⚠️ |
| プラットフォーム | Claude Code | 汎用 | 汎用 | Claude |
| 中規模タスク 1 回あたりのコスト | $0.35-1.75 | $1-10 | 変動 | $0.01-0.1 |

## 利用可能な team

| Team | 内容 | ドキュメント |
|---|---|---|
| **web-dev-team** | web 開発 | [中文](teams/web-dev-team/README.md) · [English](teams/web-dev-team/README.en.md) · [日本語](teams/web-dev-team/README.ja.md) |

## インストール

### 前提依存

| 依存 | 用途 | macOS | Linux |
|---|---|---|---|
| bash ≥ 3.2 | setup.sh / hooks | システム標準 | システム標準 |
| jq | settings.json マージ | `brew install jq` | `apt install jq` / `dnf install jq` |
| gum | インタラクティブ UI | `brew install gum` | [charmbracelet/gum](https://github.com/charmbracelet/gum#installation) |
| git | hook で変更ファイル数を計算 | システム標準 | システム標準 |
| Claude Code | インストール済 team の実行 | [ドキュメント](https://claude.com/claude-code) | 同上 |

Windows ユーザーは WSL2 を使ってください。ネイティブ Windows は非対応。

### 手順

```bash
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams
bash setup.sh   # インタラクティブ：install / reinstall / remove + team 選択 + 対象プロジェクト選択
```

インストール後、プロジェクト内で team コマンドを実行（例：`/web-dev-team <要望>`）。コマンド詳細は上記の team ドキュメント参照。

## 貢献

貢献したい方（新 team の開発 / フレームワーク改善）は [CONTRIBUTING.ja.md](./CONTRIBUTING.ja.md) を参照。
