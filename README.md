# Venomous AI Teams

基于 Claude Code 的专业 AI team 商店。每个 team 是一个能装到用户项目里的能力包。

## 当前状态

**重构第一阶段**——架构骨架定稿，具体 team 内容待第二阶段填充。

- ✅ 四层架构定稿（sub-agent / slash command / hook / 公共设施）
- ✅ 命名空间锁定（多 team 可共存）
- ✅ 反幻觉机制（独立 sub-agent 反向挑刺）
- ⏳ web-dev-team 具体角色 prompt
- ⏳ setup.sh 重写（多 team 安装 / 卸载 / 列表）

## 仓库结构

```
.claude/                    # 本仓库自身的 Claude Code 配置（开发框架时用）
├── CLAUDE.md               # 框架开发规范（≤ 40 行）
├── settings.json           # 权限配置
└── agents/审查员.md        # 反向挑刺 sub-agent

teams/                      # 产物：可装到用户项目的 team 包
└── web-dev-team/           # Web 开发方向（占位骨架）

__memo__/                   # 开发者本地记忆（gitignore，README 除外）
├── README.md
└── YYYYMMDD_xxx.md         # 跨会话的架构决定 / 踩坑教训

setup.sh                    # 安装脚本（待重写）
```

## 给框架开发者

读 `.claude/CLAUDE.md` 和 `__memo__/README.md` 即可上手。

## 给用户

⏳ **当前不可用**。setup.sh 待重写、web-dev-team 内容待填充。

重写完成后形式大致如下（**当前请勿执行**，会因找不到旧 team 报错）：

```bash
bash setup.sh --install web-dev-team /path/to/your-project
```
