#!/usr/bin/env bash
set -euo pipefail
FORCE=0
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force|-f) FORCE=1; shift ;;
    *) TARGET="$1"; shift ;;
  esac
done
if [[ -z "$TARGET" || ! -d "$TARGET/.git" ]]; then
  echo "usage: install.sh [--force] /path/to/git/repo" >&2
  exit 2
fi
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DST="$TARGET/.githooks"

existing="$(git -C "$TARGET" config --get core.hooksPath || true)"
if [[ -n "$existing" && "$existing" != ".githooks" && "$existing" != ".githooks/" && "$FORCE" -ne 1 ]]; then
  echo "core.hooksPath already set to '$existing'. Re-run with --force to overwrite." >&2
  exit 1
fi

mkdir -p "$DST"
cp -f "$HERE/hooks/pre-commit" "$DST/pre-commit"
cp -f "$HERE/hooks/pre-push" "$DST/pre-push"
chmod +x "$DST/pre-commit" "$DST/pre-push"

if ! git -C "$TARGET" config core.hooksPath .githooks; then
  echo "git config core.hooksPath failed — hooks copied but NOT wired" >&2
  exit 1
fi
verify="$(git -C "$TARGET" config --get core.hooksPath)"
echo "Installed git hooks → $DST (core.hooksPath=$verify)"
echo "Note: outbound ship still uses ship-gate / run-gates."
echo "Bypass force/delete guard: GIT_HOOKS_ALLOW_FORCE=1"
