#!/usr/bin/env bash
# 将本仓库 skills/ 下的技能安装到个人 Cursor 技能目录 (~/.cursor/skills/)。
# 默认创建符号链接（修改仓库即时生效）。加 --copy 改为复制。
# 以 _ 开头的目录（如 _template）会被跳过。
#
# 用法:
#   bash scripts/install.sh
#   bash scripts/install.sh --copy

set -euo pipefail

COPY=0
if [[ "${1:-}" == "--copy" ]]; then
  COPY=1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$REPO_ROOT/skills"
DEST_DIR="$HOME/.cursor/skills"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "找不到 skills 目录: $SRC_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

for dir in "$SRC_DIR"/*/; do
  name="$(basename "$dir")"
  case "$name" in
    _*) continue ;;
  esac

  link="$DEST_DIR/$name"
  rm -rf "$link"

  if [[ "$COPY" -eq 1 ]]; then
    cp -R "$dir" "$link"
    echo "[copied] $name"
  else
    ln -s "$dir" "$link"
    echo "[linked] $name"
  fi
done

echo ""
echo "完成。技能已安装到: $DEST_DIR"
