# 设计工件：OpenDesign

<!-- 何时读：用户明确要求设计探索时。init 时项目用 OpenDesign 才生成；把 <workspace> 换成工作区目录 basename（如 hy-iot）。 -->

本工作区的设计探索产物统一放在 `.scratch/<feature>/opendesign/`，由根仓库版本化。它不是 `/to-spec` 的默认产出。

## 触发

- 只有用户明确要求设计探索/原型设计时，才创建 `opendesign/`。
- `/to-spec` 默认只写 `spec.md`；没有设计需求时不要建空目录。
- 这里的“设计”指 OpenDesign 的设计探索产物（HTML、图片、设计说明）。
- `/prototype` 的代码原型是另一类工件：仍放在目标 repo 的 `prototype/<name>` 分支，按 `/prototype` skill 执行。

## 位置

- 唯一真源：`.scratch/<feature>/opendesign/`。
- 该目录就是 OpenDesign project 的 `baseDir`，也是 project root。
- 目录必须自包含：入口页、CSS、图片、字体、脚本都在目录内；不要引用 `../` 之外的资源。
- 不跨 feature 共享目录。公共设计系统通过 OpenDesign 的 `designSystem` 引用，不复制进 feature。

## 项目命名

- `name`：`<workspace>/<feature-slug>`
- 显式 `id`（仅在使用 `create_project` 时）：`<workspace>.<feature-slug>`；本规则的默认路径仍是 `import-folder`
- `<feature-slug>` 与 `.scratch/<feature>/` 目录名一致，保持 ASCII。
- OpenDesign 项目列表是平的；`name` 里的 `/` 只是显示约定，不会产生二级项目。
- `id` 只允许 `[A-Za-z0-9._-]{1,128}`；`/` 会被拒绝。省略 id 时会被 slugify 成 `<workspace>-<feature>-<4hex>`，层级信息丢失。
- 一个 feature 只保留一个 project。多个设计方向放在同一 project 的不同入口或子目录；只有需要不同 design system 时才拆 project。
- 不使用完整绝对路径或机器相关路径命名 project；统一用短码 `<workspace>`。同一工作区多 checkout 时再加 `-main`、`-wt2` 等后缀。
- `<workspace>` 是工作区目录 basename；工作区改名时同步替换，不要改成绝对路径。

## 创建流程

```bash
mkdir -p .scratch/<feature>/opendesign
od project list
od project import-folder .scratch/<feature>/opendesign --name "<workspace>/<feature>"
```

- 先 `od project list` 查重；folder import 不防重。
- 记下返回的 project id，写入 `opendesign/README.md`。
- 默认 name 是文件夹 basename `opendesign`，所有项目会同名，所以必须显式 `--name`。
- 优先用 `import-folder`：它把 `baseDir` 固定到 `.scratch/<feature>/opendesign/`。
- 不要用 MCP `create_project` 代替：它不绑定 `baseDir`，生成文件会落在 OpenDesign 管理目录，不在 `.scratch`。

## README

每个 `opendesign/` 必须有 `README.md`，模板见 `docs/agents/templates/opendesign-README.md`（项目里没有这份模板时，按下面的字段写）。至少记录：

- 对应 spec
- project name 与 id
- 入口文件（以 import 返回的 `entryFile` 为准）
- 状态
- 使用的 design system
- 已提升到的目标位置（如果有）

## spec 与工单

有设计时，spec 增加：

```md
## Design

- 入口：`opendesign/index.html`
- 项目：`<workspace>/<feature-slug>`（id: `<project-id>`）
- 状态：exploring
```

- 工单从 `.scratch/<feature>/issues/NN-*.md` 用 `../opendesign/index.html` 引用。
- 没有设计时不要加空的 `## Design`。

## 生命周期

- `exploring`：可以频繁修改；根仓库按需提交。
- `decided`：决定后更新 `README.md` 和 spec，提交一次。
- `promoted`：需要跟代码同生命周期或团队展示时，导出到目标 repo 或团队文档；`.scratch` 保留真源或链接，不双写。
- `archived`：feature 归档时 `opendesign/` 随 `.scratch/<feature>/` 一起走；OpenDesign project 可删除，静态产物仍在根 git 里，必要时重新 import 并更新 README 的 project id。

## 版本化与禁止

<!-- 下面两条 .gitignore / pre-commit 是多仓工作区的约定；项目里没有对应配置时，改成项目实际情况或删掉 -->
- 根仓库管理 `.scratch/`，设计文件随根仓库版本化；不依赖 OpenDesign 内部历史作为唯一记录。
- 根 `.gitignore` 对 `.scratch/**/opendesign/{dist,build,target}/` 做了例外，设计构建产物也会被跟踪。
- 提交前确认没有 `projects/` 或 `archive/`；`.githooks/pre-commit` 会拦截。
- 不把 OpenDesign 产物直接当生产代码。
- 不在 `.scratch` 之外复制第二份真源；需要展示时导出，不双写。
- 不跨 feature 共享设计目录。
