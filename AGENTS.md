# Skills repo — conventions

`Claude/` is the source of truth. Each skill is `Claude/<name>/SKILL.md`, linked into `~/.claude/skills/<name>` **one link per skill** (symlink on macOS/Linux, junction on Windows). Nothing is copied; edits are live.

## Create a skill
1. `Claude/<name>/SKILL.md` — frontmatter `name: <name>` (same as the folder), `description:` with the trigger phrases, `disable-model-invocation: true` only for manual launchers (`grill-me`, `plan-clean-structure`).
2. Keep the body lean: rules, tables, one template. Refer to sibling skills as `../<name>/SKILL.md`.
3. Run the linker. A new folder is invisible to Claude until it is linked.

## Remove a skill
Delete the folder, run the linker — it prunes the dangling link.

## Linker
| OS | Command |
|---|---|
| macOS / Linux | `./link-skills.sh` (`--dry-run` to preview) |
| Windows | `powershell -ExecutionPolicy Bypass -File .\link-skills.ps1` (`-DryRun` to preview) |

Re-run after every `git pull` — a pulled skill folder is not linked automatically. The linker never overwrites a real (non-link) folder in `~/.claude/skills`.

## Local-only skills
`Claude/pr-description/` is git-ignored but still linked like the others.

## Other folders
`docs/` — reference material, not linked. Root `grill-me/`, `grilling/`, `to-prd/` — legacy copies, not linked.
