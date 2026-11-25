# harness-workflow

给 Codex、Claude Code 等 agent 用的项目工作流路由 skill。骨架用 [Matt Pocock 的 skills](https://github.com/mattpocock/skills)，另外借用 [pstack](https://github.com/backnotprop/pstack) 里理解代码、影响面、对抗评审和去 AI 腔的技能。

它只做三件事：

1. **初始化**：读代码，生成拆分式 `AGENTS.md`。入口文件不超过 200 行，细节放进 `docs/agents/` 下的专题文档。新项目直接拆分，老项目先问。入口固定带一节「工程原则」（最简实现、分层生长、优先成熟库、先查已有依赖等 7 条），老项目已有同义规则的保留原文，只补缺的。最后直接运行 Matt 的 `setup-matt-pocock-skills`，按它的提示配置 issue tracker 和领域文档。
2. **信号提示**：每次收到请求先判断规模，选一个剧本。命中信号就提示要不要触发对应的官方技能。这些官方技能大多只能手动触发。
3. **串联**：用简短的剧本把官方技能串起来。盘问、spec、拆票、TDD、评审、复盘、交接都交给官方技能，本 skill 不重写。

原则是少脚本、多交互，状态只记在 Markdown 里。拆分规则参考 [为什么一个巨大的指令文件会失败](https://walkinglabs.github.io/learn-harness-engineering/zh/lectures/lecture-04-why-one-giant-instruction-file-fails/)。

完整说明（设计理念、工作原理、安装、使用、常见问题）见 [docs/GUIDE.md](docs/GUIDE.md)。

## 安装

需要 Node.js（用来跑 `npx skills`）、bash 和网络。

```bash
git clone https://github.com/yangyigit/harness-workflow.git
cd harness-workflow
scripts/install.sh --dry-run   # 先看会执行哪些命令
scripts/install.sh
```

脚本会先从本地目录全局安装本 skill，再按 `dependencies.txt` 安装官方技能。已经装过的技能会跳过，不会覆盖你自己链接的同名技能。

默认装到 Codex 和 Claude Code。要换别的工具，用 `SKILL_AGENTS` 指定，名字以 `npx skills` 支持的为准：

```bash
SKILL_AGENTS="codex cursor" scripts/install.sh
```

### 只装到某个项目

不想装全局时，在目标项目根目录下加 `--project` 运行，会装到该项目的 `.agents/skills/`，并生成该项目的 `skills-lock.json`：

```bash
cd /path/to/your-project
/path/to/harness-workflow/scripts/install.sh --project --dry-run
/path/to/harness-workflow/scripts/install.sh --project
```

判断「已安装」时只看该项目里的目录，不看全局。项目里的 `.agents/` 和 `skills-lock.json` 要不要进 git，由项目自己的 `.gitignore` 决定。

## 更新

```bash
git pull
scripts/install.sh --update
```

`--update` 会依次做下面几件事：

1. 重装本 skill。本地目录装的 skill 不在 `npx skills update` 的范围内，所以改了本 skill 之后也要跑这一条
2. 补装清单里缺的官方技能
3. 对清单里的技能运行 `npx skills update -g -y`，和上游比对，有变化才更新
4. 检查清单里的技能是否都已就位。缺了就列出名字并以退出码 1 结束，多半是上游改名或删除了

脚本管不了的情况：

- 官方技能升级后开始依赖新的技能时，需要手动把新技能加进 `dependencies.txt`
- 检查更新会访问 GitHub API，次数多了可能被限流，这时先设置 `GITHUB_TOKEN` 再跑

## 依赖的官方技能

完整清单见 `dependencies.txt`。

| 来源 | 自动使用 | 命中信号才提示 |
|---|---|---|
| Matt | `tdd`、`diagnosing-bugs`、`codebase-design`、`domain-modeling` | `setup-matt-pocock-skills`、`grill-with-docs`、`grill-me`、`to-spec`、`to-tickets`、`implement`、`prototype`、`improve-codebase-architecture`、`code-review`、`retro`、`handoff` |
| pstack | — | `how`、`why`、`blast-radius`、`interrogate`、`unslop` |

另有几个被其他技能调用的依赖，也在清单里：`grilling`（`grill-with-docs` 调用）、`arena` 和 `in-your-own-words`（`interrogate` 调用）。

Matt 和 pstack 都有 `tdd`，只装 Matt 的版本。

## 怎么用

装好后正常提需求就行。几个例子：

- 仓库里没有 `AGENTS.md` 时，会提示先初始化
- 「做个导出功能」这类没说什么算做完的需求，会提示先用 `grill-with-docs` 盘问
- 改了公共组件，会提示用 `blast-radius` 看影响面
- 说「收工」，会更新 `docs/agents/progress.md` 并提示 `retro`

直接说技能名（如「grill」「拆任务」）就直接进入，不再确认。选过「直接做」或说过「别问了」，本会话不再提示同一个技能。

## 生成到项目里的文件

| 文件 | 谁写 |
|---|---|
| `AGENTS.md`、`docs/agents/{project,architecture,stack,conventions,commands,progress}.md` | 本 skill |
| `docs/agents/{issue-tracker,domain,triage-labels}.md` | `setup-matt-pocock-skills` |
| `GLOSSARY.md`、`docs/adr/` | `domain-modeling` |
| `.scratch/<feature>/` | `to-spec`、`to-tickets`（本地 tracker 时） |

## 目录结构

```
harness-workflow/
├── SKILL.md              路由、提示规则、文件分工、硬约束
├── docs/GUIDE.md         完整说明文档
├── dependencies.txt      依赖的官方技能清单
├── scripts/install.sh    安装与更新
├── references/
│   ├── signals.md        信号表与技能查找路径
│   ├── playbooks.md      剧本
│   └── init.md           初始化与 AGENTS.md 拆分
└── assets/templates/     AGENTS.md 和专题文档模板
```

## 修改本 skill

- 信号表里增删官方技能时，同步修改 `dependencies.txt`
- 不要把官方技能的内容抄进来，有需要就在信号表里指向它
- 改完运行 `scripts/install.sh --update`，让已安装的副本生效
