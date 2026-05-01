# 貢献ガイド

[中文](./CONTRIBUTING.md) | [English](./CONTRIBUTING.en.md) | 日本語

## はじめに

```bash
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams

# 必読
cat .claude/CLAUDE.md           # フレームワーク開発規範（≤ 40 行ハード制限）
cat __memo__/README.md          # セッション跨ぎ記憶メカニズム
```

## リポジトリ構成

```
venomous-ai-teams/
├── setup.sh                    # インストールエントリ（インタラクティブ）
├── scripts/                    # setup.sh モジュール群
│   ├── install.sh
│   ├── remove.sh
│   ├── settings.sh             # fragments → settings.json マージ
│   ├── platform.sh             # 環境チェック（bash / jq / gum）
│   ├── safety.sh               # パス安全性
│   ├── teams.sh                # team レジストリ
│   └── ui.sh                   # gum インタラクティブ UI
├── teams/                      # 各 team パック（ユーザープロジェクトに入る成果物）
│   └── <team>/
│       ├── README.md           # team ドキュメント（4 セクション：定位/コマンド/ワークフロー/削除）
│       ├── README.en.md
│       ├── README.ja.md
│       └── .claude/            # ユーザーの .claude/ に 1:1 ミラー
│           ├── commands/<team>/        # slash command
│           ├── agents/<team>/          # 独立 sub-agent
│           ├── hooks/<team>/           # bash hook スクリプト
│           ├── templates/<team>/       # テンプレート
│           └── .fragments/<team>.json  # hook + permissions フラグメント（settings.json に合成）
├── .claude/                    # 本リポジトリ自身の Claude Code 設定（フレームワーク開発用、ユーザーには入らない）
│   ├── CLAUDE.md               # フレームワーク開発規範（≤ 40 行ハード制限）
│   ├── settings.json
│   ├── agents/
│   │   └── 开发审查员.md       # 反対挑刺 sub-agent（新 team 開発時に必須 spawn、team 成果物の审查员と区別）
│   └── hooks/
│       └── load-memo.sh        # SessionStart で `status: 进行中` の memo todo を注入
├── __memo__/                   # セッション跨ぎアーキテクチャ判断 / 踏み抜き教訓（README 以外 gitignore）
│   ├── README.md               # memo 執筆規範
│   └── YYYYMMDD_xxx.md         # 各 memo（開発者ローカル）
└── __playground__/             # team 実走テスト場（fake app + 生成された spec、gitignore）
```

## 新しい team を作る最小フロー

1. `__memo__/20260429_team公共规范.md`（共通規範、ハードルール）を読む
2. `teams/<your-team>/` 配下に `.claude/` 構造をミラー
3. prompt ファイルは行数ハード制限を守る（架构者 ≤ 50 / 执行者 ≤ 35 / sub-agent ≤ 60 / slash command ≤ 80）
4. `.fragments/<team>.json`（hook + permissions フラグメント）を書く
5. 実走テスト：`bash setup.sh` で `__playground__/<fake-app>/` にインストールして実シナリオで動かす
6. 完了宣言前に `.claude/agents/开发审查员.md` を spawn、独立した 2 インスタンス以上がゼロ所見でようやく通過

## 重要な制約

- `.claude/{agents,commands,hooks}/`、`teams/*/.claude/{agents,commands,hooks,settings.json}`、`setup.sh` を編集 → 必ず开发审查员を spawn（`.claude/CLAUDE.md` 参照）
- `__memo__/` 内の `status: 已定稿` の memo は編集しない（実際に誤りがある場合を除く）
- commit に `Co-Authored-By: Claude` などの AI 署名は付けない
- bash スクリプトは macOS bash 3.2+ 互換（`mapfile` / `declare -A` / `\s\d\w` 等禁止）

詳細は `.claude/CLAUDE.md` 参照。
