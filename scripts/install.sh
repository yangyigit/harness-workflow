#!/usr/bin/env bash
# 安装或更新 harness-workflow 及 dependencies.txt 里的官方技能。
# 用法：scripts/install.sh [--project] [--update] [--dry-run]
#   默认：装本 skill，补装缺的官方技能，已装的跳过
#   --project：装到当前目录的项目里（.agents/skills/），不装全局。要在目标项目根目录下运行
#   --update：再把清单里的官方技能更新到上游最新版
# 环境变量 SKILL_AGENTS 指定装到哪些工具，默认 "codex claude-code"。
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
agents="${SKILL_AGENTS:-codex claude-code}"
dry_run=false
update=false
project=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --update) update=true ;;
    --project) project=true ;;
    *) echo "未知参数：$arg" >&2; exit 2 ;;
  esac
done

if $project; then
  base="$PWD"
  add_scope=""
  update_scope="-p"
  echo "安装到项目：$base"
else
  base="$HOME"
  add_scope="-g"
  update_scope="-g"
fi

run() {
  echo "+ $*"
  # 不给子命令 stdin：npx 会吃掉下面 while read 循环里还没读的清单行
  $dry_run || "$@" </dev/null
}

# 已装过的跳过，避免覆盖用户自己链接的同名技能。
installed() {
  for dir in "$base/.agents/skills" "$base/.codex/skills" "$base/.claude/skills"; do
    [ -e "$dir/$1/SKILL.md" ] && return 0
  done
  return 1
}

# 本地目录装的 skill 不在 npx skills update 的范围内，所以每次都重装。
run npx -y skills add "$root" $add_scope -y -a $agents

all=()
while read -r repo names; do
  missing=()
  for name in $names; do
    all+=("$name")
    if installed "$name"; then echo "= 已安装，跳过：$name"; else missing+=("$name"); fi
  done
  [ ${#missing[@]} -eq 0 ] && continue
  run npx -y skills add "$repo" $add_scope -y -a $agents --skill "${missing[@]}"
done < <(grep -vE '^[[:space:]]*(#|$)' "$root/dependencies.txt")

# 只更新经 skills CLI 从 GitHub 装的技能。用户自己链接的同名技能不在锁文件里，不会被改动。
if $update; then
  run npx -y skills update $update_scope -y "${all[@]}"
fi

$dry_run && exit 0

lost=()
for name in "${all[@]}"; do
  installed "$name" || lost+=("$name")
done
if [ ${#lost[@]} -gt 0 ]; then
  echo "! 这些技能没装上，可能是上游改名或删除了：${lost[*]}" >&2
  echo "  请核对 dependencies.txt 和 references/signals.md" >&2
  exit 1
fi
echo "完成：本 skill 和 ${#all[@]} 个官方技能都已就位"
