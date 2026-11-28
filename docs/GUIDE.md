# harness-workflow 说明文档

README 是速查，本文讲清楚它为什么这样设计、内部怎么工作、怎么装、怎么用。内容对应 `9ca765d` 及之后的版本。

## 1. 它是什么

一个给 Codex、Claude Code 等编码 agent 用的 skill。它本身不实现开发流程，只做两件事：

- **初始化**：读项目代码，生成拆分式的 `AGENTS.md` 和 `docs/agents/` 专题文档，最后引导你配置 Matt 的技能。
- **路由**：每次你提需求，先判断任务规模、选一个剧本；看到特定信号时，提醒你该用哪个官方技能。

具体流程（盘问、写 spec、拆票、TDD、评审、复盘、交接）都交给两套官方技能：

| 来源 | 仓库 | 在本 skill 里的角色 |
|---|---|---|
| Matt（Matt Pocock） | `mattpocock/skills` | 工作流骨架：grill → spec → tickets → implement → review → retro |
| pstack | `backnotprop/pstack` | 理解代码（`how`、`why`）、影响面（`blast-radius`）、对抗评审（`interrogate`）、去 AI 腔（`unslop`） |

## 2. 要解决的问题

1. **旧版太重**：旧版 harness-workflow 自己实现整套流程，用 JSON 记状态、配了 6 万字节的脚本，还有四阶段复盘。用起来步骤多，改起来也难。
2. **单个巨大的 AGENTS.md 会失效**：文件一长，模型读不全，中间的规则容易被忽略，改一处要通读全文。
3. **官方技能不会自己出现**：Matt 和 pstack 的编排类技能大多设成只能手动触发（Claude Code 里是 `disable-model-invocation: true`，Codex 里是 `allow_implicit_invocation: false`）。agent 不会主动调用，你又很难记住什么时候该用哪一个。

## 3. 设计理念

### 3.1 只做路由，不重写

官方技能有人维护，会持续升级。本 skill 只记录「什么信号对应哪个技能」，触发时去读那个技能自己的 `SKILL.md` 照做：

- 官方技能的步骤和本 skill 冲突时，以官方技能为准
- 不把官方技能的内容抄进来，也不改它们的文件
- 官方技能没装时，提示安装，不凭记忆模仿它的做法

这样上游一升级，你直接受益；本 skill 也一直很小，入口 `SKILL.md` 不到 90 行。

### 3.2 少脚本，多交互

唯一的脚本是 `scripts/install.sh`，只负责装依赖。其余全部是 Markdown 指令。

会改变工作节奏、或需要你拍板的环节，一律只提示、给编号选项、等你选，不擅自开流程。小改动不打扰你。

### 3.3 入口是路由器，不是百科

依据 [为什么一个巨大的指令文件会失败](https://walkinglabs.github.io/learn-harness-engineering/zh/lectures/lecture-04-why-one-giant-instruction-file-fails/)：

| 规则 | 数值 |
|---|---|
| 入口 `AGENTS.md` | 不超过 200 行，目标 120 行内，只放每次任务都要用的 |
| 专题文档 | 每篇 50–150 行，按需读；入口索引里写明「何时必读」 |
| 硬约束 | 不超过 15 条，每条写明违反的后果；最关键的在顶部写一次、底部重申一次 |
| 模块专属规则 | 超过 30 行，下沉为该目录下的 `AGENTS.md`（Codex 等工具会就近读取） |

拿不准一条内容放哪时：每次任务都用的放入口；某类任务才用的放专题；某个目录才用的放模块 `AGENTS.md`；基本用不上的不写。

### 3.4 状态只放在 Markdown 里

| 状态 | 位置 |
|---|---|
| 当前任务、基线、待办、交接 | `docs/agents/progress.md` |
| 术语 | `GLOSSARY.md` |
| 决策 | `docs/adr/` |
| spec 和 tickets | `.scratch/<feature>/`（本地 tracker 时） |

没有 JSON 状态文件，也没有状态机脚本。历史靠 git。

### 3.5 项目规则优先

- 老项目已有的规则比本 skill 更严时，以项目为准。例如项目要求「每个任务先确认再动手」，就覆盖本 skill 的「小改动直接做」
- 已有的 `CLAUDE.md`、`.cursorrules` 等规则文件，没经你同意不删除、不覆盖
- 老项目已有同义规则的，保留项目原文，只补缺的

### 3.6 工程原则

初始化时，每个项目的入口都会写入这 7 条（不计入硬约束条数）：

1. 选能满足当前需求的最简单实现。不做预防性抽象，不加「万一以后用得上」的配置层
2. 系统分层生长：先跑通最小的端到端版本，能跑了再往上加。不因为未来可能的复杂度，拆掉当前能正常工作的东西
3. 组件保持模块化，关注点分离清楚
4. 优先用成熟、有人维护的第三方库。没有特别硬的理由，不自己重写
5. 动手前先查项目已有依赖能做什么，再决定加新包还是自己写
6. 架构决策按长远做，不接受「先凑合用，以后再说」的临时方案
7. 先看成熟产品怎么解决同一个问题，用验证过的模式，不从零发明

第 1 条和第 6 条不冲突：做的范围取最小，选的方案要经得起长期用。

## 4. 工作原理

### 4.1 组成

```text
harness-workflow/
├── SKILL.md              入口：路由步骤、提示规则、文件分工、硬约束
├── dependencies.txt      依赖的官方技能清单，install.sh 读取
├── scripts/install.sh    安装与更新
├── references/
│   ├── signals.md        信号表、技能查找路径
│   ├── playbooks.md      剧本：每类任务的步骤和可能提示的技能
│   └── init.md           初始化、AGENTS.md 拆分、运行 setup-matt-pocock-skills
├── assets/templates/     AGENTS.md 和专题文档模板
└── docs/GUIDE.md         本文
```

agent 加载本 skill 时只读 `SKILL.md`；`references/` 下的文档按需读取，模板只在初始化时用。

### 4.2 每次请求的路由

收到请求后，agent 不问你，先做这四步：

1. **定规模**

   | 规模 | 判断 | 处理 |
   |---|---|---|
   | S | 改动在一个文件内，意图清楚（改文案、修明显的 bug、加个参数） | 直接做 |
   | M | 涉及几个文件，一个会话能做完 | 需要一句话的验收标准 |
   | L | 跨模块，涉及接口、权限或数据结构，或者一个会话做不完 | 走 spec + tickets |

   拿不准时按大一级处理，但只多问一个问题。
2. **选剧本**：从 `references/playbooks.md` 选一个，把步骤写进计划
3. **扫信号**：对照 `references/signals.md`，命中就提示，没命中就直接开干
4. **先读后写**：依次读 `AGENTS.md`、与任务相关的专题文档、`docs/agents/progress.md`

### 4.3 信号表

信号分两类。

**自动使用**：这几个官方技能允许模型直接调用，场景对上就用，不问你。

| 场景 | 技能 |
|---|---|
| 写或改业务逻辑 | `tdd`（项目没有测试框架时不用，先问你要不要引入） |
| 修 bug、测试失败、性能退化 | `diagnosing-bugs` |
| 设计或调整模块接口 | `codebase-design` |
| 讨论中出现新术语、做出取舍 | `domain-modeling` |

**命中就提示**：19 条信号按优先级排列，例如「该用哪个技能」提示 `ask-matt`，「路线看不清的大工程」提示 `wayfinder`，「没说什么算做完」提示 `grill-with-docs`，「改了公共组件」提示 `blast-radius`，「收工」提示 `retro`。完整列表见 `references/signals.md`。

提示的规则：

- 一次只提一个技能；同时命中多条时，只提最靠前的
- 你选了「直接做」或说过「别问了」，本会话不再提同一个技能
- 你直接说出技能名或环节名（如「grill」「拆任务」「收工」），直接进入，不再确认
- 不在步骤进行中打断，等当前步骤告一段落再问

提示的样子：

> 需求里没写什么算做完，而且会动到登录和权限两个模块。要先对齐一下吗？
> 1. 先盘问：`grill-with-docs`，顺手把术语和决策记进 GLOSSARY.md 和 ADR
> 2. 直接做，我把假设列在最后让你确认

### 4.4 怎么调用官方技能

你同意后，agent 按下面的顺序找技能，找到第一个就读它的 `SKILL.md` 照做：

1. 项目级：`.agents/skills/<名字>/SKILL.md`
2. 全局：`~/.agents/skills/<名字>/SKILL.md`
3. 工具自带目录：`~/.codex/skills/`、`~/.claude/skills/`

都找不到，就告诉你没装，问你要不要运行 `scripts/install.sh`。

### 4.5 剧本

| 剧本 | 什么时候用 | 可能提示的技能 |
|---|---|---|
| 小改动（S） | 改文案、样式、配置，一行修复 | 不提示 |
| 修 bug | 报错、结果不对、给了复现步骤 | 复现不了提示 `grill-me`；同一模块第二次出 bug 提示 `improve-codebase-architecture`；修的是公共代码提示 `blast-radius` |
| 新功能（M） | 几个文件、一个会话能做完 | 没有验收标准时提示 `grill-with-docs`；完成前提示 `code-review` |
| 大功能（L） | 跨模块，或一个会话做不完 | 依次提示 `grill-with-docs` → `to-spec` → `to-tickets` → `implement`；涉及权限、迁移、并发时提示 `interrogate`；全部完成后提示 `retro` |
| 重构 | 整理、抽离、拆分、太乱 | 范围不清时提示 `improve-codebase-architecture`；完成前提示 `blast-radius` |
| 性能优化 | 慢、卡 | 先测量再改，没有前后数字不算完成 |
| 接手老项目 / 初始化 | 没有 `AGENTS.md`，或你说「初始化」 | 走 `init`，最后直接运行 `setup-matt-pocock-skills` |
| 依赖升级 | 升级某个库 | 完成后提示 `blast-radius` |
| 问答 / 调研 | 只问不改 | 较深的问题提示 `how` 或 `why` |
| 开工 / 续接 | 「继续」「接着做」 | 不提示，读 `progress.md`、跑基线后直接开始 |
| 收工 | 「收工」「今天先这样」 | 提示 `retro`；要换工具或交给别人时改为提示 `handoff` |

`implement` 内部会调用 `tdd` 和 `code-review`，走了 `implement` 的任务不再单独提示 `code-review`。

### 4.6 初始化流程

1. **判断新老项目**。满足任一条就算老项目：已有 `AGENTS.md`、`CLAUDE.md`、`.cursorrules`、`.cursor/rules/`、`.github/copilot-instructions.md` 之一；业务源文件超过约 20 个；git 提交超过约 10 次
2. **只读代码**：依次看清单文件（`package.json` 等）、顶层两层目录、入口文件、构建/lint/测试/CI 配置、抽样代码（最多 8 个）、已有规则文件。每条事实记下来源路径。环境文件只记文件名，不读内容
3. **只问代码里读不出来的**：一次最多 5 个，比如项目一句话介绍、「完成前必跑」的命令、绝对不能碰的目录。不知道的标「待确认」，不编
4. **拆不拆**：新项目直接拆；老项目先给出预估行数，再问你三选一：拆分 / 不拆（压到 200 行内）/ 只补缺。已有 `AGENTS.md` 的，动手前先给你看差异摘要
5. **写入**：入口 `AGENTS.md`，加上 `docs/agents/` 下的 project、architecture、stack、conventions、commands、progress。不到 20 行的专题并入相邻文档；超过 150 行的按子主题再拆（如 `conventions-api.md`）
6. **自查**：行数、硬约束条数、工程原则是否齐全、每篇专题是否写了「何时必读」；验证命令真跑一次，结果写进 `progress.md` 的「基线」；列出所有「待确认」
7. **运行 `setup-matt-pocock-skills`**：不再单独问你要不要做。已经有 `docs/agents/issue-tracker.md` 的跳过；技能没装就先问你要不要装。它的每个问题都照原样问你，写入前先给你看草稿。仓库没有 GitHub/GitLab 远程时，会推荐本地 markdown tracker。它跑完后再检查一次入口行数

### 4.7 文件分工

| 文件 | 谁写 |
|---|---|
| `AGENTS.md`、`docs/agents/{project,architecture,stack,conventions,commands,progress}.md` | 本 skill |
| `docs/agents/design-artifacts.md`（项目用 OpenDesign 时才有） | 本 skill |
| `docs/agents/{issue-tracker,domain,triage-labels}.md`，以及 `AGENTS.md` 里的 `## Agent skills` 小节 | `setup-matt-pocock-skills` |
| `GLOSSARY.md`、`docs/adr/` | `domain-modeling`（经 `grill-with-docs` 等调用） |
| `.scratch/<feature>/` | `to-spec`、`to-tickets`（本地 tracker 时） |

Matt 管的文件，本 skill 只读不写。本 skill 生成的文件名特意避开了 Matt 的 `issue-tracker.md`、`domain.md`、`triage-labels.md`。

### 4.8 安装脚本

skills CLI（`npx skills`）不支持在 frontmatter 里声明依赖，所以需要一个脚本把本 skill 和官方技能一起装上。

`dependencies.txt` 每行一个仓库，后面跟技能名，`#` 开头是注释：

```text
mattpocock/skills tdd diagnosing-bugs ...
backnotprop/pstack how why blast-radius ...
```

`install.sh` 的执行顺序：

1. 从本地目录安装本 skill。本地目录装的 skill 不在 `npx skills update` 的范围内，所以每次都重装
2. 逐行读清单。已经装过的技能跳过，没装的批量安装。判断「已装」看三个目录：`.agents/skills`、`.codex/skills`、`.claude/skills`（全局时在 `~` 下，项目级时在当前目录下）。跳过已装的，是为了不覆盖你自己链接的同名技能
3. 加了 `--update` 时，对清单里的技能运行 `npx skills update`。它对比锁文件里记的版本和 GitHub 上的最新版，有变化才更新；不在锁文件里的（比如你自己链接的）不受影响
4. 最后检查清单里每个技能是否都已就位。缺了就列出名字，以退出码 1 结束

两个实现细节：

- `--project` 时以当前目录为根，安装不加 `-g`，更新用 `-p`
- 执行的命令一律不接收标准输入。否则 `npx` 会把清单里还没读的行读走，导致后面的仓库被漏装

## 5. 安装

### 5.1 前置条件

- Node.js（用来跑 `npx skills`）
- bash（macOS 自带的 3.2 可用）
- 网络：要访问 npm 和 GitHub。agent 在沙箱里运行时，需要你授权联网

### 5.2 全局安装

```bash
git clone https://github.com/yangyigit/harness-workflow.git
cd harness-workflow
scripts/install.sh --dry-run   # 只打印要执行的命令，不联网
scripts/install.sh
```

默认装到 Codex 和 Claude Code。要换别的工具，用 `SKILL_AGENTS` 指定，名字以 `npx skills` 支持的为准（如 `codex`、`claude-code`、`cursor`、`windsurf`、`opencode`）：

```bash
SKILL_AGENTS="codex cursor" scripts/install.sh
```

### 5.3 只装到某个项目

在目标项目根目录下运行：

```bash
cd /path/to/your-project
/path/to/harness-workflow/scripts/install.sh --project --dry-run
/path/to/harness-workflow/scripts/install.sh --project
```

技能会装到 `.agents/skills/`，并生成 `skills-lock.json`。它们要不要进 git，由项目自己的 `.gitignore` 决定。

### 5.4 确认装好了

脚本最后打印「完成：本 skill 和 N 个官方技能都已就位」就说明齐了。也可以直接看目录：

```bash
ls ~/.agents/skills          # 全局
ls .agents/skills            # 项目级
```

### 5.5 卸载

```bash
npx skills remove -g harness-workflow     # 全局
npx skills remove harness-workflow        # 在项目根目录下，项目级
```

官方技能要一并删除的话，把技能名接在后面。

## 6. 使用

### 6.1 第一次在项目里用

在项目里对 agent 说「初始化」或「生成 AGENTS.md」。项目里没有 `AGENTS.md` 时，你提第一个需求它也会先提示初始化。

老项目的典型过程：

1. agent 读完代码，告诉你「这是老项目，写成单个文件约 N 行」，问你拆分、不拆还是只补缺
2. 问几个代码里读不出来的问题（项目一句话介绍、验证命令等）
3. 给你看入口草稿和差异摘要，你确认后再写
4. 跑一次验证命令，记下基线，列出「待确认」
5. 进入 `setup-matt-pocock-skills`，问你 issue tracker 放哪，给你看草稿后写入

写完的改动不会自动提交，你看过后再决定。

### 6.2 日常

正常提需求就行，agent 会按规模和信号决定直接做还是先问你。几个例子：

| 你说 | agent 的反应 |
|---|---|
| 「按钮文案改成『提交』」 | S 级，直接改，跑相关验证 |
| 「做个导出功能」 | 没有验收标准，提示先用 `grill-with-docs` 盘问 |
| 「这个表格组件改一下默认分页」 | 公共组件，改完提示用 `blast-radius` 看影响面 |
| 「登录模块怎么做的权限判断？」 | 问答，读代码回答；问题较深时提示 `how` |
| 「继续昨天的」 | 读 `progress.md`，跑基线，说明从哪继续，然后直接做 |
| 「收工」 | 更新 `progress.md`，提示 `retro` |

### 6.3 直接点名

知道要用哪个技能时，直接说名字，不会再确认。也可以用工具自带的手动触发方式，比如 Codex 里输入 `$grill-with-docs`，Claude Code 里输入 `/grill-with-docs`。

### 6.4 不想被提示

选「直接做」或说「别问了」，本会话不再提示同一个技能。下一个会话会重新开始提示。

### 6.5 场景速查

| 我想…… | 用 |
|---|---|
| 不知道该用哪个技能 | `ask-matt` |
| 规划一个路线还看不清的大工程 | `wayfinder` |
| 把需求问清楚 | `grill-with-docs`（不想留文档用 `grill-me`） |
| 把讨论整理成 spec | `to-spec` |
| 把 spec 拆成可独立完成的 ticket | `to-tickets` |
| 按 spec 或 ticket 写代码 | `implement` |
| 先做个原型看看 | `prototype` |
| 查官方文档、API 事实并写成笔记 | `research` |
| 搞懂某段代码怎么工作、该放哪 | `how` |
| 搞懂当初为什么这样设计 | `why` |
| 看一个改动会影响哪些地方 | `blast-radius` |
| 找人挑刺、压力测试 | `interrogate` |
| 评审改动 | `code-review` |
| 改善架构 | `improve-codebase-architecture` |
| 去掉文档、注释里的 AI 腔 | `unslop` |
| 复盘这次会话 | `retro` |
| 换工具或交给别人继续 | `handoff` |

## 7. 更新与维护

### 7.1 跟随官方升级

```bash
cd harness-workflow
git pull
scripts/install.sh --update              # 全局
# 项目级：在项目根目录下运行 install.sh --project --update
```

### 7.2 修改本 skill

- 信号表里增删官方技能时，同步修改 `dependencies.txt`
- 官方技能升级后开始依赖新技能时，要手动把新技能加进 `dependencies.txt`
- 不要把官方技能的内容抄进来，在信号表里指向它
- 改完后重新运行 `install.sh`（全局或 `--project`），已安装的副本才会更新。副本是复制过去的，不会自动同步

## 8. 常见问题

**agent 说某个技能没装**：运行 `scripts/install.sh`（项目级加 `--project`）。它只补缺，不会动已装的。

**install.sh 最后报「这些技能没装上」**：多半是上游改名或删除了技能。到官方仓库确认新名字，再改 `dependencies.txt` 和 `references/signals.md`。

**`npx` 卡住，或报 `ENOTFOUND`**：沙箱没有网络。给 agent 授权联网后重跑。

**检查更新时报 GitHub 限流**：先设置 `GITHUB_TOKEN` 再跑。

**项目已有 `CLAUDE.md`**：初始化时会把内容合并进来，原文件保留；是否改成一行 `@AGENTS.md` 引用由你决定。`setup-matt-pocock-skills` 会改 `CLAUDE.md` 而不是 `AGENTS.md`，这是它自己的规则。

**新写的文档让项目 lint 变红**：有些 ESLint 配置（如 `@antfu/eslint-config` 开了 `markdown: true`）会检查 Markdown。初始化后要跑一次项目的 lint；表格对齐之类的问题可以只对新文件运行 `eslint --fix`。

**Matt 和 pstack 有同名技能**：两边都有 `tdd` 和 `teach`，清单里只装 Matt 的版本。

## 9. 已知限制

- 信号由模型判断，不是硬规则，偶尔会漏提或多提。你可以随时直接点名技能
- 官方技能之间的依赖关系靠手工维护在 `dependencies.txt` 里
- 本地安装的副本不会自动跟随源目录更新，改完要重跑 `install.sh`
- 项目没有测试框架时，`tdd` 用不了；agent 会问你要不要引入，不会擅自添加
