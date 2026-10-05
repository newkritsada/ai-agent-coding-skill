#!/usr/bin/env bash
# link-skills.sh -- one symlink per skill: ./Claude/<name> -> ~/.claude/skills/<name>
# Re-run after creating or deleting a skill, and after `git pull` brings new ones.
#   ./link-skills.sh            # link new, refresh existing, prune links to deleted skills
#   ./link-skills.sh --dry-run  # show only
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/Claude" && pwd -P)"
TARGET="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DRY=0; [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]] && DRY=1
run() { if (( DRY )); then echo "    $*"; else "$@"; fi; }

# Old layout: the whole dir was one link. Remove the link (never its contents).
FRESH=0
if [[ -L "$TARGET" ]]; then echo "replace dir link: $TARGET"; run rm "$TARGET"; FRESH=$DRY; fi
run mkdir -p "$TARGET"

# link every Claude/<name>/SKILL.md
for dir in "$SOURCE"/*/; do
  [[ -f "$dir/SKILL.md" ]] || continue
  name="$(basename "$dir")"; dest="$TARGET/$name"
  if (( ! FRESH )) && [[ -e "$dest" && ! -L "$dest" ]]; then echo "skip (real dir, not a link): $dest"; continue; fi
  echo "link:  $name"; run ln -sfn "${dir%/}" "$dest"
done

# prune links into SOURCE whose skill folder is gone
for link in "$TARGET"/*; do
  [[ -L "$link" ]] || continue
  t="$(readlink "$link")"
  if [[ "$t" == "$SOURCE"/* && ! -d "$t" ]]; then echo "prune: $(basename "$link")"; run rm "$link"; fi
done
