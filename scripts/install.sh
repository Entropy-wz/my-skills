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
# path = skill dir for kind=skill; kit root for kind=kit.
# Always ends with status 0 so set -e + command substitution cannot abort
# when the last scanned directory simply lacks SKILL.md.
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
        printf '%s|%s|kit\n' "$name" "${dir%/}"
      fi
    done
  fi

  return 0
}

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

# Remove dest: unlink symlink/junction only; never follow into the repo.
remove_dest() {
  local link="$1"
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    return 0
  fi
  if [ -L "$link" ]; then
    rm -f "$link"
  else
    rm -rf "$link"
  fi
}

# Place path into dest via copy or symlink.
place_path() {
  local src="$1" dest="$2"
  if [ "$COPY" -eq 1 ]; then
    if [ -d "$src" ]; then
      cp -R "$src" "$dest"
    else
      cp "$src" "$dest"
    fi
  else
    ln -s "$src" "$dest"
  fi
}

install_skill() {
  local name="$1" path="$2"
  local link="$DEST_DIR/$name"

  remove_dest "$link"
  place_path "$path" "$link"
  echo "[$([ "$COPY" -eq 1 ] && echo copied || echo linked)] $name"
}

# Kit: SKILL.md at dest root + sibling tools/docker/agents/README from kit root.
install_kit() {
  local name="$1" kit_root="$2"
  local link="$DEST_DIR/$name"
  local skill_dir="$kit_root/skill"
  local label="kit:$name"
  local f sibling

  remove_dest "$link"
  mkdir -p "$link"

  # skill/* → dest/
  for f in "$skill_dir"/* "$skill_dir"/.[!.]*; do
    [ -e "$f" ] || continue
    place_path "$f" "$link/$(basename "$f")"
  done

  for sibling in tools docker agents README.md; do
    if [ -e "$kit_root/$sibling" ]; then
      place_path "$kit_root/$sibling" "$link/$sibling"
    fi
  done

  echo "[$([ "$COPY" -eq 1 ] && echo copied || echo linked)] $label"
}

install_one() {
  local name="$1" path="$2" kind="$3"
  if [ "$kind" = "kit" ]; then
    install_kit "$name" "$path"
  else
    install_skill "$name" "$path"
  fi
}

SEEN_LIST=""
skill_count=0
kit_count=0
found_any=0

SOURCE_FILE="$(mktemp)"
trap 'rm -f "$SOURCE_FILE"' EXIT
collect_sources >"$SOURCE_FILE"

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
done <"$SOURCE_FILE"

if [ "$found_any" -eq 0 ]; then
  echo "未发现任何可安装 skill（skills/*/SKILL.md 或 kits/*/skill/SKILL.md）" >&2
  exit 1
fi

echo ""
echo "完成。技能已安装到: $DEST_DIR"
echo "来源: ${skill_count} skill(s), ${kit_count} kit skill(s)"
