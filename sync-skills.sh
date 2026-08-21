#!/usr/bin/env bash
#
# sync-skills.sh -- copy the Claude skills in this repo to their install targets.
#
# Targets:
#   ~/.claude/skills                                  (global skills)
#   <pluton-monorepo>/.claude/skills                  (project skills)
#
# Each target's skills directory is REPLACED so it matches Claude/ exactly.
#
# Usage:
#   ./sync-skills.sh              # sync to all targets
#   ./sync-skills.sh --global     # global only
#   ./sync-skills.sh --project    # project only
#   ./sync-skills.sh --dry-run    # show what would happen
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Claude"
GLOBAL_DEST="$HOME/.claude/skills"
PROJECT_DEST="${PLUTON_MONOREPO:-$HOME/Desktop/skill-lane/project/gitlab/pluton-monorepo}/.claude/skills"

DO_GLOBAL=1
DO_PROJECT=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --global)  DO_PROJECT=0 ;;
    --project) DO_GLOBAL=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

[ -d "$SRC" ] || { echo "source skills dir not found: $SRC" >&2; exit 1; }

sync_to() {
  local dest="$1" label="$2"

  if [ ! -d "$(dirname "$dest")" ]; then
    echo "skip $label: parent dir missing ($(dirname "$dest"))"
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would replace $label -> $dest"
    rsync -an --delete --exclude '.DS_Store' --exclude '.gitignore' --exclude 'sync-skills.sh' \
      "$SRC/" "$dest/" | sed 's/^/    /'
    return
  fi

  # If the destination is a symlink (old linking setup), drop it first.
  [ -L "$dest" ] && rm "$dest"

  mkdir -p "$dest"
  rsync -a --delete --exclude '.DS_Store' --exclude '.gitignore' --exclude 'sync-skills.sh' \
    "$SRC/" "$dest/"
  echo "synced $label -> $dest"
}

[ "$DO_GLOBAL"  -eq 1 ] && sync_to "$GLOBAL_DEST"  "global"
[ "$DO_PROJECT" -eq 1 ] && sync_to "$PROJECT_DEST" "pluton-monorepo"

exit 0
