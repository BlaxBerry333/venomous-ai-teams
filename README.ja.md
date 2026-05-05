# venomous-ai-teams

[English](./README.md) | [中文](./README.zh.md) | 日本語

Claude Code のマルチロール + spec フロー + 反幻覚レビューを 1 コマンドでインストール可能な team にパッケージ化。<br/>
team を入れると、メイン対話にその領域の「考える → 書く → 審査」パイプラインが入る。

## 利用可能な team

| Team | 内容 | ドキュメント |
|---|---|---|
| **web-dev-team** | web 開発 | [中文](teams/web-dev-team/README.zh.md) · [English](teams/web-dev-team/README.md) · [日本語](teams/web-dev-team/README.ja.md) |
| **doc-writing-team** | 出典付き markdown ドキュメント執筆 | [中文](teams/doc-writing-team/README.zh.md) · [English](teams/doc-writing-team/README.md) · [日本語](teams/doc-writing-team/README.ja.md) |
| **web-design-team** | Web デザイン + プロトタイプ | [中文](teams/web-design-team/README.zh.md) · [English](teams/web-design-team/README.md) · [日本語](teams/web-design-team/README.ja.md) |

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
