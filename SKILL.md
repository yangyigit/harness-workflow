---
name: harness-workflow
description: 项目工作流路由。负责两件事：一是根据代码生成拆分式 AGENTS.md（新项目直接拆，老项目先问）；二是每次收到请求时判断任务类型，命中信号就提示我是否触发 Matt Pocock 或 pstack 的官方技能（这些技能大多只能手动触发）。用于初始化项目、生成或精简 AGENTS.md、接手老项目、做新功能、修 bug、重构、评审、收工、交接，或我说「开工 / 收工 / 交接 / 这个怎么做」时。
---

# Harness Workflow

这个 skill 只做路由，不重写流程。盘问、spec、拆票、TDD、评审、复盘、交接都交给官方技能：

- Matt Pocock：`mattpocock/skills`（骨架）
- pstack：`backnotprop/pstack`（理解代码、影响面、对抗评审、去 AI 腔）

官方技能大多设置为只能手动触发。这个 skill 的作用是看到信号就提醒我，我同意后再去读对应技能的 SKILL.md 并照做。原则是少脚本、多交互，状态只记在 Markdown 里。

## 1. 收到请求先路由（每次都做，不用问）

1. **定规模**
   - S：改动在一个文件内，意图清楚（改文案、修明显的 bug、加个参数）。直接做
   - M：涉及几个文件，一个会话能做完。需要一句话的验收标准
   - L：跨模块，涉及接口、权限或数据结构，或者一个会话做不完。走 spec + tickets
2. **选剧本**：从 `references/playbooks.md` 里选一个，把步骤写进计划
3. **扫信号**：对照 `references/signals.md`，命中就提示，没命中就直接开干
4. **先读后写**：依次读 `AGENTS.md`、与任务相关的专题文档、`docs/agents/progress.md`

规模拿不准时按大一级处理，但只多问一个问题，不多走一整套流程。

## 2. 怎么提示

先用一句话说看到了什么信号，再给 2-3 个编号选项，推荐项放第一个：

> 需求里没写什么算做完，而且会动到登录和权限两个模块。要先对齐一下吗？
> 1. 先盘问：`grill-with-docs`，顺手把术语和决策记进 GLOSSARY.md 和 ADR
> 2. 直接做，我把假设列在最后让你确认

规则：
- 一次只提示一个技能。同时命中多个时，只提信号表里最靠前的
- 我选了「直接做」或说过「别问了」，本会话不再提同一个技能
- 我直接说出技能名或环节名（如「grill」「拆任务」「收工」），就直接进入，不再确认
- 不在步骤进行中打断，等当前步骤告一段落再问

## 3. 怎么触发官方技能

- 我选了某个选项，或直接说出技能名：按 `references/signals.md` 末尾的路径找到它的 SKILL.md，读完照做。官方技能的步骤和本 skill 冲突时，以官方技能为准，本 skill 只补充本仓库的文件位置
- 找不到这个技能：告诉我没装，给出安装命令，不要凭记忆模仿它的做法
- 不把官方技能的内容抄进本 skill，也不改官方技能的文件。要更新就用 `npx skills update`

## 4. 本 skill 自己负责的环节

| 环节 | 什么时候 | 细则 |
|---|---|---|
| 初始化 `init` | 仓库没有 `AGENTS.md`；或我说「初始化 / 接手 / 生成 AGENTS」 | `references/init.md` |
| 拆分 `split` | `AGENTS.md` 超过 200 行，或硬约束超过 15 条 | `references/init.md` 第 4 节 |
| 完成前验证 | 声称完成之前 | 跑 `AGENTS.md` 里「完成前必跑」的命令并贴出结果 |
| 进度记录 | 开工、收工、范围外的发现 | 写 `docs/agents/progress.md` |

## 5. 文件分工

| 文件 | 内容 | 谁写 |
|---|---|---|
| `AGENTS.md` | 入口和路由。不超过 200 行，目标 120 行内 | 本 skill |
| `docs/agents/{project,architecture,stack,conventions,commands}.md` | 专题文档 | 本 skill |
| `docs/agents/progress.md` | 当前任务、基线、待办、简短交接 | 本 skill |
| `docs/agents/{issue-tracker,domain,triage-labels}.md` | Matt 技能的配置 | `setup-matt-pocock-skills` |
| `GLOSSARY.md`、`docs/adr/` | 术语、决策记录 | Matt 的 `domain-modeling`（经 `grill-with-docs`） |
| `.scratch/<feature>/` | spec 和 tickets（本地 tracker 时） | `to-spec`、`to-tickets` |

Matt 管的文件，本 skill 只读不写。模板在 `assets/templates/`。

## 6. 硬约束

1. 没跑过验证命令，不说「完成」。验证失败时，不许改断言、加 skip、调阈值
2. 同时只推进一个 ticket。想顺手改别的，记进 `progress.md` 的「待办」
3. 不做任务范围外的重构
4. 开工前基线是红的，先告诉我，不在红基线上叠新功能
5. 写进 `AGENTS.md` 的规则，必须说清它拦住什么行为；说不清就不写
6. 改完 `AGENTS.md` 后，行数超过 200 或硬约束超过 15 条，提示 `split`
7. 老项目已有的规则文件（`CLAUDE.md`、`.cursorrules` 等），没经我同意不删除、不覆盖
8. 不复制、不改写官方技能。官方技能没装就提示安装

## 7. 参考文档

| 文档 | 何时读 |
|---|---|
| `references/signals.md` | 每次路由扫信号；找官方技能的安装路径 |
| `references/playbooks.md` | 每次路由选剧本 |
| `references/init.md` | 初始化，生成或拆分 AGENTS.md |
