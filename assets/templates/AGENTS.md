# AGENTS.md

<!-- 入口文件：只放每次任务都要用的内容。≤200 行，目标 120 行内。细节写进 docs/agents/。 -->

## 项目概览
<项目名>：<一句话，说清做什么、给谁用>。
技术栈：<语言 / 框架 / 构建 / 测试>。仓库形态：<单包 / monorepo>。

## 快速命令
- 安装：`<cmd>`
- 开发：`<cmd>`
- 测试：`<cmd>`
- 完成前必跑：`<cmd>`

## 硬约束
<!-- 不超过 15 条，只写违反了会出事的。格式：规则 — 违反的后果 -->
1. <规则> — <后果>

## 工程原则
<!-- 固定内容，原样写入，不计入硬约束条数。项目已有同义规则的，保留项目原文，只补缺的 -->
1. 选能满足当前需求的最简单实现。不做预防性抽象，不加「万一以后用得上」的配置层
2. 系统分层生长：先跑通最小的端到端版本，能跑了再往上加。不因为未来可能的复杂度，拆掉当前能正常工作的东西
3. 组件保持模块化，关注点分离清楚
4. 优先用成熟、有人维护的第三方库。没有特别硬的理由，不自己重写
5. 动手前先查项目已有依赖能做什么，再决定加新包还是自己写。不要想当然认为库里没有
6. 架构决策按长远做。不接受「先凑合用，以后再说」的临时方案
7. 先看成熟产品怎么解决同一个问题，用验证过的模式，不从零发明

第 1 条和第 6 条不冲突：做的范围取最小，选的方案要经得起长期用。

## 模块地图
| 路径 | 职责 |
|---|---|
| `src/xxx` | <一句话> |

## 文档索引
| 文档 | 内容 | 何时必读 |
|---|---|---|
| `docs/agents/project.md` | 业务、角色、核心流程 | 做新功能、看不懂业务名词时 |
| `docs/agents/architecture.md` | 模块职责、依赖方向、边界 | 新增模块、跨模块改动时 |
| `docs/agents/stack.md` | 框架、版本、依赖用法 | 引入依赖、用不熟悉的 API 时 |
| `docs/agents/conventions.md` | 命名、目录、写法、测试、提交 | 每次写代码前 |
| `docs/agents/commands.md` | 全部命令及说明 | 构建、测试、发布出问题时 |
| `docs/agents/progress.md` | 当前任务、基线、待办 | 每次开工 |
| `docs/agents/design-artifacts.md` | OpenDesign 设计稿的位置、命名、生命周期 | 我要求设计探索时 |

## 工作流入口
<!-- 多仓工作区（根下有 projects/<repo>）原样用；单仓项目把 projects/<repo> 读作仓库根，删掉 Repo 行的要求 -->
由 `harness-workflow` skill 路由：S 级直接做；其余按下面的入口走，命中信号时先问我，我直接说技能名就直接进入。下面的技能都在 harness-workflow 的 `dependencies.txt` 里，Claude Code 写 `/名字`，Codex 写 `$名字`；找不到就运行它的 `scripts/install.sh`，不凭记忆模仿。

### 选路与配置
- 不知道用哪个技能：`/ask-matt`。
- 第一次用 `/to-spec`、`/to-tickets`、`/wayfinder`、`/code-review` 之前：`/setup-matt-pocock-skills`，生成 `docs/agents/issue-tracker.md` 等配置。

### 主流程：新功能 / 重构
- L 级（跨模块或一个会话做不完）：`/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement` → `/code-review` → `/retro`。`/to-tickets` 之前不清空、不压缩上下文；之后每张工单清空上下文再单独 `/implement`。M 级盘问后直接 `/implement`，不写 spec 和工单。不需要留 GLOSSARY / ADR 时，用 `/grill-me` 代替 `/grill-with-docs`。
- 规格和工单：`.scratch/<feature>/`（`spec.md`、`issues/<NN>-<slug>.md`）。每张工单必须写 `Repo: projects/<repo>`；缺这一行的工单不开工，先补上。
- 实现：进入 `projects/<repo>`，用 `/implement` 读取工单，同时只推进一张；它按缝合点调 `tdd` 一次一个红→绿切片，收尾自动跑 `/code-review` 并提交到当前分支。
- 审查：在同一个 `projects/<repo>` 内用 `/code-review`。规范轴读 `projects/<repo>/AGENTS.md` 里的代码规范部分：硬约束、工程原则，以及它链接的 `docs/agents/conventions.md`；不另建 `CODING_STANDARDS.md`。规格轴读对应的 `.scratch/<feature>/` spec 和工单，它在仓库外，`/code-review` 自己搜不到，要显式传给它。
- 复盘：`/retro`。只改环境、检查、规范：机械性错误加 lint、hook 或 CI 检查；判断题写进 `projects/<repo>/AGENTS.md` 的代码规范部分，入口放不下就写进它链接的 `docs/agents/conventions.md`；找文件难就补导航指针。不写历史流水账，当前状态只记在 `docs/agents/progress.md`。

### 入口匝道：汇入主流程
- 疑难 bug：`/diagnosing-bugs`。先建立一条能对这个 bug 变红的紧凑反馈循环，再提假设；修好留下回归测试，同一会话接 `/retro`。
- 大而模糊的工程（绿地项目，或路线还看不清）：`/wayfinder`，在 `.scratch/<initiative>/map.md` 建决策地图，一次解一张决策工单，只产出决定、不写交付代码。路清晰后回到 `/to-spec`，不直接跳 `/implement`。
- 代码越改越乱、同一模块第二次出 bug：`/improve-codebase-architecture` 找加深机会，挑中的一个带回 `/grill-with-docs`。

### 研究与原型
- 研究：`/research` 只查一手资料（官方文档、源码、规格），结论写进 `docs/research/<topic>.md`，每条标来源。
- 代码原型：`/prototype` 在目标 repo 从 main 切出的 `prototype/<name>` 分支上做一次性原型，不合入 main；结论和分支名写回对应工单。
- 设计探索：仅在我明确要求时，用 OpenDesign 在 `.scratch/<feature>/opendesign/` 生成设计稿；`/to-spec` 默认不创建设计目录。OpenDesign 不在 `dependencies.txt`，要单独配置。见 `docs/agents/design-artifacts.md`。

### 理解与把关（pstack）
- 这段代码怎么工作、该放哪一层：`/how`；当初为什么这么设计：`/why`。只读代码回答，不改文件。
- 改了公共函数、共享组件、接口或配置：`/blast-radius` 列出影响面，再决定改法。
- 涉及权限、支付、数据迁移、并发：`/interrogate` 做对抗评审。
- 写了较多文档、PR 描述或注释：`/unslop` 去掉 AI 腔。

### 交接
- 换工具、换目录或交给别人：`/handoff`。同一工具里明天接着做，只在 `docs/agents/progress.md` 记一行。

### 不用点名
- 场景对上就自动用：`tdd`（写业务逻辑）、`diagnosing-bugs`（修 bug）、`codebase-design`（设计模块接口）、`domain-modeling`（新术语、取舍，写 `GLOSSARY.md` 和 `docs/adr/`）、`writing-for-agents`（改 `AGENTS.md` 或技能）。
- 由其它技能内部调用：`grilling`（盘问类）、`arena` 和 `in-your-own-words`（`/interrogate`）。

<!-- setup-matt-pocock-skills 会在这里追加 ## Agent skills 小节 -->

## 重申
- <最关键的硬约束 1>
- <最关键的硬约束 2>
- 没跑「完成前必跑」的命令，不算完成
