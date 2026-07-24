#!/usr/bin/env bash
# Install skills from this toolkit into ~/.cursor/skills/.
# Sources:
#   1) skills/<name>/SKILL.md  (skip _*)
#   2) kits/<name>/skill/SKILL.md  (skip _*)
# Default: symlink. Pass --copy to copy instead.
#
# Compatible with Bash 3.2+ (macOS /bin/bash) — no mapfile / declare -A.
#
# Usage:
#   bash scripts/install.sh
#   bash scripts/install.sh --copy

set -euo pipefail

COPY=0
if [ "${1:-}" = "--copy" ]; then
  COPY=1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"
KITS_DIR="$REPO_ROOT/kits"
DEST_DIR="$HOME/.cursor/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "找不到 skills 目录: $SKILLS_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

# Emit name|path|kind lines (skills first, then kits).
collect_sources() {
  local dir name skill_md skill_dir

  if [ -d "$SKILLS_DIR" ]; then
    for dir in "$SKILLS_DIR"/*/; do
      [ -d "$dir" ] || continue
      name="$(basename "$dir")"
      case "$name" in _*) continue ;; esac
      skill_md="${dir}SKILL.md"
      if [ -f "$skill_md" ]; then
        printf '%s|%s|skill\n' "$name" "${dir%/}"
      fi
    done
  fi

  if [ -d "$KITS_DIR" ]; then
    for dir in "$KITS_DIR"/*/; do
      [ -d "$dir" ] || continue
      name="$(basename "$dir")"
      case "$name" in _*) continue ;; esac
      skill_dir="${dir}skill"
      skill_md="${skill_dir}/SKILL.md"
      if [ -f "$skill_md" ]; then
        printf '%s|%s|kit\n' "$name" "$skill_dir"
      fi
    done
  fi
}

# Return 0 if name is already in space-separated SEEN_LIST (skill names have no spaces).
name_seen() {
  local needle="$1"
  local n
  for n in $SEEN_LIST; do
    if [ "$n" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

install_one() {
  local name="$1" path="$2" kind="$3"
  local link="$DEST_DIR/$name"
  local label="$name"
  if [ "$kind" = "kit" ]; then
    label="kit:$name"
  fi

  rm -rf "$link"

  if [ "$COPY" -eq 1 ]; then
    cp -R "$path" "$link"
    echo "[copied] $label"
  else
    ln -s "$path" "$link"
    echo "[linked] $label"
  fi
}

SEEN_LIST=""
skill_count=0
kit_count=0
found_any=0

# Process substitution works on Bash 3.2; avoid mapfile / associative arrays.
while IFS='|' read -r name path kind || [ -n "${name:-}" ]; do
  [ -n "${name:-}" ] || continue
  found_any=1

  if name_seen "$name"; then
    echo "警告: 名称冲突，跳过 ${kind}: ${name}（已存在于已安装列表）" >&2
    continue
  fi

  SEEN_LIST="${SEEN_LIST} ${name}"
  install_one "$name" "$path" "$kind"

  if [ "$kind" = "kit" ]; then
    kit_count=$((kit_count + 1))
  else
    skill_count=$((skill_count + 1))
  fi
done <<EOF
$(collect_sources)
EOF

if [ "$found_any" -eq 0 ]; then
  echo "未发现任何可安装 skill（skills/*/SKILL.md 或 kits/*/skill/SKILL.md）" >&2
  exit 1
fi

echo ""
echo "完成。技能已安装到: $DEST_DIR"
echo "来源: ${skill_count} skill(s), ${kit_count} kit skill(s)"
