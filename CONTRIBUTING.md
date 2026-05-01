# 贡献指南

中文 | [English](./CONTRIBUTING.en.md) | [日本語](./CONTRIBUTING.ja.md)

## 上手

```bash
git clone https://github.com/BlaxBerry333/venomous-ai-teams.git
cd venomous-ai-teams

# 必读
cat .claude/CLAUDE.md           # 框架开发规范（≤ 40 行硬规）
cat __memo__/README.md          # 跨会话开发记忆机制
```

## 仓库结构

```
venomous-ai-teams/
├── setup.sh                    # 安装入口（交互式）
├── scripts/                    # setup.sh 拆分模块
│   ├── install.sh
│   ├── remove.sh
│   ├── settings.sh             # fragments → settings.json 合成
│   ├── platform.sh             # 环境检查（bash / jq / gum）
│   ├── safety.sh               # 路径安全
│   ├── teams.sh                # team 注册表
│   └── ui.sh                   # gum 交互
├── teams/                      # 各 team 包（装到用户项目的产物）
│   └── <team>/
│       ├── README.md           # team 说明（4 段：定位/命令/工作流/删除）
│       ├── README.en.md
│       ├── README.ja.md
│       └── .claude/            # 1:1 镜像到用户项目的 .claude/
│           ├── commands/<team>/        # slash command
│           ├── agents/<team>/          # 独立 sub-agent
│           ├── hooks/<team>/           # bash hook 脚本
│           ├── templates/<team>/       # 模板文件
│           └── .fragments/<team>.json  # hook + permissions 片段（合成进 settings.json）
├── .claude/                    # 本仓库自身的 Claude Code 配置（开发框架时用，不会装到用户）
│   ├── CLAUDE.md               # 框架开发规范（≤ 40 行硬规）
│   ├── settings.json
│   ├── agents/
│   │   └── 开发审查员.md       # 反向挑刺 sub-agent（开发新 team 时强制 spawn，跟产物 team 的审查员区分）
│   └── hooks/
│       └── load-memo.sh        # SessionStart 注入 status: 进行中 的 memo 挂账
├── __memo__/                   # 跨会话架构决定 / 踩坑教训（gitignore，README 除外）
│   ├── README.md               # memo 写作规范
│   └── YYYYMMDD_xxx.md         # 各项 memo（开发者本地）
└── __playground__/             # team 实跑测试场（fake app + 生成的 spec，gitignore）
```

## 开发新 team 的最小流程

1. 读 `__memo__/20260429_team公共规范.md`（公共规范，硬规）
2. 在 `teams/<your-team>/` 下镜像 `.claude/` 结构
3. 写 prompt 文件遵守行数硬规（架构者 ≤ 50 / 执行者 ≤ 35 / sub-agent ≤ 60 / slash command ≤ 80）
4. 写 `.fragments/<team>.json`（hook + permissions 片段）
5. 实跑测试：`bash setup.sh` 装到 `__playground__/<fake-app>/` 跑真实场景
6. 改完后宣告完成前 spawn `.claude/agents/开发审查员.md` 至少 2 个独立实例都零发现才算通过

## 关键约束

- 改 `.claude/{agents,commands,hooks}/`、`teams/*/.claude/{agents,commands,hooks,settings.json}`、`setup.sh` → 必须 spawn 开发审查员（见 `.claude/CLAUDE.md`）
- 不改 `__memo__/` 内已 `status: 已定稿` 的 memo（除非真有错）
- commit 不带 `Co-Authored-By: Claude` 等 AI 署名
- bash 脚本兼容 macOS bash 3.2+（禁 `mapfile` / `declare -A` / `\s\d\w` 等）

详见 `.claude/CLAUDE.md`。
