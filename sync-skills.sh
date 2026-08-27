#!/usr/bin/env bash
#
# sync-skills.sh -- mirror ./Claude into the global skills directory.
#
# ./Claude is the single source of truth. The target is REBUILT from it, so any
# skill that exists only in the target is DELETED. Uses plain cp -R; no rsync.
#
# Usage:
#   ./sync-skills.sh --dry-run    # show what would change
#   ./sync-skills.sh              # do it
#
# Works in Git Bash / WSL / macOS / Linux.

set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/Claude" && pwd -P)"
TARGET="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

# Never copied into the target.
EXCLUDES=(
  'sync-skills.sh'
  'sync-skills.cmd'
  '.gitignore'
  '.DS_Store'
  'Thumbs.db'
  '.git'
)

DRY_RUN=0
case "${1:-}" in
  --dry-run|-n) DRY_RUN=1 ;;
  -h|--help)    sed -n '2,13p' "$0"; exit 0 ;;
  '')           ;;
  *)            echo "unknown option: $1" >&2; exit 1 ;;
esac

RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; CYN=$'\033[36m'; DIM=$'\033[2m'; OFF=$'\033[0m'

is_excluded() {
  local name="$1" e
  for e in "${EXCLUDES[@]}"; do
    [[ "$name" == "$e" ]] && return 0
  done
  return 1
}

# Top-level entries of SOURCE that should be copied.
payload() {
  local entry name
  for entry in "$SOURCE"/* "$SOURCE"/.[!.]*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    is_excluded "$name" && continue
    printf '%s\n' "$name"
  done
}

[[ -d "$SOURCE" ]] || { echo "source skills dir not found: $SOURCE" >&2; exit 1; }

parent="$(dirname "$TARGET")"
[[ -d "$parent" ]] || { printf '%sABORT: parent directory does not exist (%s)%s\n' "$RED" "$parent" "$OFF" >&2; exit 1; }

# Refuse to rebuild a target that is (or contains) the source -- that would
# delete the source itself.
if [[ -e "$TARGET" ]]; then
  real="$(cd "$TARGET" 2>/dev/null && pwd -P || printf '%s' "$TARGET")"
  if [[ "$real" == "$SOURCE" ]]; then
    printf '%sABORT: target resolves to the source (%s)%s\n' "$RED" "$real" "$OFF" >&2
    exit 1
  fi
  case "$SOURCE/" in
    "$real"/*) printf '%sABORT: source lives inside the target%s\n' "$RED" "$OFF" >&2; exit 1 ;;
  esac
fi

printf '%sSource of truth: %s%s\n' "$GRN" "$SOURCE" "$OFF"
printf '%s->             %s%s\n' "$CYN" "$TARGET" "$OFF"
(( DRY_RUN )) && printf '%sDRY RUN%s\n' "$YLW" "$OFF"

if (( DRY_RUN )); then
  if [[ -e "$TARGET" ]]; then
    while IFS= read -r name; do
      printf '   %sdelete%s %s\n' "$RED" "$OFF" "$name"
    done < <(cd "$TARGET" && ls -A)
  fi
  while IFS= read -r name; do
    printf '   %scopy  %s %s\n' "$GRN" "$OFF" "$name"
  done < <(payload)
  printf '%sdry run -- nothing written%s\n' "$DIM" "$OFF"
  exit 0
fi

# A symlink/junction at the target is removed as a link, not followed.
if [[ -L "$TARGET" ]]; then
  rm "$TARGET"
elif [[ -d "$TARGET" ]]; then
  rm -rf "$TARGET"
fi

mkdir -p "$TARGET"
while IFS= read -r name; do
  cp -R "$SOURCE/$name" "$TARGET/"
done < <(payload)

printf '%ssynced (%s entries)%s\n' "$GRN" "$(payload | wc -l | tr -d ' ')" "$OFF"
