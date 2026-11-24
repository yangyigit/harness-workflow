# 信号表

## 1. 自动使用，不提示

这些官方技能允许模型直接调用。场景对上就用，不用问我。

| 场景 | 技能 | 来源 |
|---|---|---|
| 写或改业务逻辑 | `tdd` | Matt |
| 修 bug、测试失败、性能退化 | `diagnosing-bugs` | Matt |
| 设计或调整模块接口 | `codebase-design` | Matt |
| 讨论中出现新术语、做出取舍 | `domain-modeling` | Matt |

项目里没有测试框架时，`tdd` 不能用。告诉我，问要不要引入，不要擅自加。

## 2. 命中就提示，等我选

按顺序扫，只提最靠前命中的一个。

| # | 信号 | 提示的技能 | 来源 |
|---|---|---|---|
| 1 | 仓库没有 `AGENTS.md`；「初始化 / 接手 / 生成 AGENTS」 | `init`（本 skill） | — |
| 2 | 接下来要用 `to-spec`、`to-tickets`、`code-review`，但还没有 `docs/agents/issue-tracker.md` | `setup-matt-pocock-skills` | Matt |
| 3 | 没说什么算做完；「大概 / 类似 / 优化一下 / 做个 X 功能」；L 级任务 | `grill-with-docs`（不想留文档时用 `grill-me`） | Matt |
| 4 | 盘问结束，且是 L 级 | `to-spec` | Matt |
| 5 | spec 已确认，一个会话做不完 | `to-tickets` | Matt |
| 6 | 已有 spec 或 tickets，要开始写代码 | `implement` | Matt |
| 7 | 状态模型或 UI 方向拿不准，想先看看效果 | `prototype` | Matt |
| 8 | 「这个怎么工作 / 应该放哪 / 哪一层负责」 | `how` | pstack |
| 9 | 「为什么这么设计 / 当初为什么选 X」 | `why` | pstack |
| 10 | 「太乱 / 难维护 / 重构 / 没人敢动」；同一模块第二次出 bug | `improve-codebase-architecture` | Matt |
| 11 | 改了公共函数、共享组件、接口或配置；「这会影响什么」 | `blast-radius` | pstack |
| 12 | 涉及权限、支付、数据迁移、并发；「挑挑刺 / 压一压」 | `interrogate` | pstack |
| 13 | M/L 级任务完成前 | `code-review` | Matt |
| 14 | 写了较多文档、PR 描述或注释 | `unslop` | pstack |
| 15 | 「收工 / 复盘 / 今天先这样」；同类问题第二次出现 | `retro` | Matt |
| 16 | 上下文用到约 60%；「明天继续 / 交接 / 换工具 / 换人」 | `handoff` | Matt |

说明：
- `implement` 会在内部调用 `tdd` 和 `code-review`。走了 `implement` 的任务，第 13 条不再单独提示
- `grill-with-docs` 内部调用 Matt 的 `grilling` 和 `domain-modeling`；`interrogate` 依赖 pstack 的 `arena` 和 `in-your-own-words`。这些都已列在 `dependencies.txt`
- 交接只在要换工具、换目录或交给别人时用 `handoff`。同一工具里明天接着做，在 `progress.md` 记一行就够了

## 3. 安装路径

读技能时按顺序找，找到第一个就用：

1. 项目级：`.agents/skills/<名字>/SKILL.md`
2. 全局：`~/.agents/skills/<名字>/SKILL.md`
3. 工具自带目录：`~/.codex/skills/`、`~/.claude/skills/`

都找不到时，问我要不要运行 `scripts/install.sh`。它按 `dependencies.txt` 安装，已装的会跳过。

Matt 和 pstack 都有 `tdd` 和 `teach`，清单里只放 Matt 的版本。
