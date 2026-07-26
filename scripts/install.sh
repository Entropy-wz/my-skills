#!/usr/bin/env bash
# Install skills from this toolkit into ~/.cursor/skills/.
# Sources:
#   1) skills/**/<leaf>/SKILL.md  (skip _*; install name = leaf)
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

# Temp files cleaned on EXIT (interrupt / set -e mid-collect).
CLEANUP_FILES=""
cleanup_temps() {
  # shellcheck disable=SC2086
  rm -f $CLEANUP_FILES
}
trap cleanup_temps EXIT

track_temp() {
  CLEANUP_FILES="${CLEANUP_FILES} $1"
}

# Emit name|path|kind lines (skills first, then kits).
# Skills: exactly skills/<category>/<leaf>/SKILL.md (ADR-001); install name = leaf.
# Skip any path segment starting with _. path = skill dir for kind=skill; kit root for kit.
# find failures and invalid depths abort (exit 1). Ends with return 0 on success.
collect_sources() {
  local dir name skill_md skill_dir rel find_out find_err sort_out nslash

  if [ -d "$SKILLS_DIR" ]; then
    find_out="$(mktemp)"
    find_err="$(mktemp)"
    track_temp "$find_out"
    track_temp "$find_err"
    # Do not bury find in $(…) / heredoc — set -e must see failures.
    if ! find "$SKILLS_DIR" -type f -name SKILL.md >"$find_out" 2>"$find_err"; then
      echo "错误: find skills/**/SKILL.md 失败:" >&2
      cat "$find_err" >&2
      exit 1
    fi
    if [ -s "$find_err" ]; then
      # Some find builds write warnings to stderr while exiting 0
      cat "$find_err" >&2
    fi

    sort_out="$(mktemp)"
    track_temp "$sort_out"
    sort "$find_out" >"$sort_out"
    while IFS= read -r skill_md; do
      [ -n "$skill_md" ] || continue
      rel="${skill_md#"$SKILLS_DIR"/}"
      case "$rel" in
        _*|*/_*) continue ;;
      esac
      # Exactly category/leaf/SKILL.md (two slashes / three path components)
      nslash=$(printf '%s' "$rel" | awk -F/ '{print NF-1}')
      if [ "$nslash" -ne 2 ]; then
        echo "错误: 非法 skill 路径 '$rel'（需要 skills/<category>/<leaf>/SKILL.md）" >&2
        exit 1
      fi
      case "$rel" in
        */*/SKILL.md) ;;
        *)
          echo "错误: 非法 skill 路径 '$rel'（需要 skills/<category>/<leaf>/SKILL.md）" >&2
          exit 1
          ;;
      esac
      skill_dir="$(dirname "$skill_md")"
      name="$(basename "$skill_dir")"
      printf '%s|%s|skill\n' "$name" "$skill_dir"
    done <"$sort_out"
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

# Case-insensitive name clash (Windows dest is case-insensitive).
name_seen() {
  local needle="$1"
  local needle_lc n n_lc
  needle_lc=$(printf '%s' "$needle" | tr '[:upper:]' '[:lower:]')
  for n in $SEEN_LIST; do
    n_lc=$(printf '%s' "$n" | tr '[:upper:]' '[:lower:]')
    if [ "$n_lc" = "$needle_lc" ]; then
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
track_temp "$SOURCE_FILE"
collect_sources >"$SOURCE_FILE"

# Preflight: reject duplicate install names before any dest write (ADR-001).
while IFS='|' read -r name path kind || [ -n "${name:-}" ]; do
  [ -n "${name:-}" ] || continue
  if name_seen "$name"; then
    echo "错误: 名称冲突 ${kind}: ${name}（与已发现项重复；ADR-001 要求唯一安装名）" >&2
    exit 1
  fi
  SEEN_LIST="${SEEN_LIST} ${name}"
done <"$SOURCE_FILE"
SEEN_LIST=""

while IFS='|' read -r name path kind || [ -n "${name:-}" ]; do
  [ -n "${name:-}" ] || continue
  found_any=1

  if name_seen "$name"; then
    echo "错误: 名称冲突 ${kind}: ${name}（与已发现项重复；ADR-001 要求唯一安装名）" >&2
    exit 1
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
  echo "未发现任何可安装 skill（skills/**/SKILL.md 或 kits/*/skill/SKILL.md）" >&2
  exit 1
fi

echo ""
echo "完成。技能已安装到: $DEST_DIR"
echo "来源: ${skill_count} skill(s), ${kit_count} kit skill(s)"
