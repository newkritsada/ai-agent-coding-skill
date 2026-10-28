# Skills repo — conventions

`Claude/` is the source of truth. Each skill is `Claude/<name>/SKILL.md`, linked into `~/.claude/skills/<name>` **one link per skill** (symlink on macOS/Linux, junction on Windows). Nothing is copied; edits are live.

## Create a skill
1. `Claude/<name>/SKILL.md` — frontmatter `name: <name>` (same as the folder), `description:` with the trigger phrases, `disable-model-invocation: true` only for manual launchers (`grill-me`, `build-plan`, `plan-diagram-archify`, `plan-feature`, `build-stack`, `to-prd`).
2. Keep the body lean: rules, tables, one template. Refer to other skills by name — `/<name>` — never by a relative path, so a folder can move.
   - **Root skills** use no other skill (`grilling`, `clean-function`, `port-adapter-architecture`, `commit-checkpoint`). Keep them that way — bind roots in a composed skill instead (`clean-architecture`).
   - **Uses** — every skill starts (under its H1) with `## Uses`: a numbered list `1. \`/<name>\` — why`, direct uses only, preceded by `Load a skill by name: read \`~/.claude/skills/<name>/SKILL.md\`.` Root skills write `None — root skill.` Point at a section when only part is needed (`/clean-architecture` **Pick**).
   - **Composed skills** bind roots. Keep `Claude/docs/skills.md` (list + tree) in sync when a skill or its Uses changes.
   - **Enhance skills** (enhance another skill): say "follow `/<base>`", then state only the delta in the base's terms ("file name ends `.diagram.md` instead of `.md`"). Never restate the base's rules, formats or names — a base change must touch only the base.
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
`Claude/docs/` — `skills.md` (list + dependency tree), `plan-build-flow.md` (walkthrough); no `SKILL.md`, so the linker skips it.
`docs/` — reference material, not linked.
