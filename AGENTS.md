# Skills repo — conventions

`Claude/` is the source of truth. Each skill is `Claude/<name>/SKILL.md`, linked into `~/.claude/skills/<name>` **one link per skill** (symlink on macOS/Linux, junction on Windows). Nothing is copied; edits are live.

## Create a skill
1. `Claude/<name>/SKILL.md` — frontmatter `name: <name>` (same as the folder), `description:` with the trigger phrases, `disable-model-invocation: true` only for manual launchers (`grill-me`, `plan-clean-structure`, `plan-phased-mr`, `plan-diagram-archify`, `plan-feature-flow`).
2. Keep the body lean: rules, tables, one template. Refer to sibling skills as `../<name>/SKILL.md`.
   - **Enhance skills** (enhance another skill): say "follow `../<base>/SKILL.md`", then state only the delta in the base's terms ("add `-diagram` before `.md` in the plan file name"). Never restate the base's rules, formats or names — a base change must touch only the base.
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
