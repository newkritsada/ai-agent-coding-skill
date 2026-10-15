---
name: plan-diagram-archify
description: Plan a feature with plan-pattern (file name gets `-diagram` before `.md`) plus archify diagram types, then render the plan's flow as archify diagrams and a file-change tree in one tabbed Artifact that later runs update in place. Use instead of /plan-clean-structure when the goal is a diagram, not code. Manual launcher — invoke with /plan-diagram-archify.
disable-model-invocation: true
---

# Plan → archify diagram

## Diagram only — no code

Output = the plan file, `{dir}/` files, the Artifact. Never touch app code, tests, configs or migrations; never run §7 or change a todo `status`. Approving the plan or exiting plan mode means **render**, not build. Build code only when the user explicitly says so → `../plan-clean-structure/SKILL.md`.

## Mode

| Context | Mode |
|---|---|
| Plan mode, or args describe a feature | **Plan** |
| Otherwise | **Build** — plan per `../plan-pattern/SKILL.md` **Using a plan** |

## archify

`~/.claude/skills/archify/` or `.claude/skills/archify/` (`SKILL.md` + `bin/archify.mjs`). Missing → Plan mode: add `prereq: npx skills add tt-a1i/archify -g` to §2 **Constraints**. Build mode: ask once, install (needs Node ≥ 20.12 — prefix `PATH` with a newer nvm Node if needed), run `node <archify>/bin/archify.mjs doctor`; declined → stop.

## Plan mode

1. Follow `../plan-pattern/SKILL.md` fully. Enhance: add `-diagram` before `.md` in its file name — marks this skill; every other skill still reads it as a normal plan.
2. Pick 1–3 types (first = primary); ask in grilling only on a tie. Add the template blocks.

| Plan signal | Type |
|---|---|
| §6 steps / branches / exits | `workflow` (default) |
| API → service → DB / external over time | `sequence` |
| many modules, services, storage | `architecture` |
| data moves / transforms / PII | `dataflow` |
| status changes, retries | `lifecycle` |
| entity / relation / migration | `erd` |
| new classes, interfaces, ports | `class` |
| folder tree is the point | `tree` |
| phased rollout | `timeline` |
| latency / step cost | `waterfall` |

## Build mode

1. Read §3–§6, the Diagram table, frontmatter `diagram:`. No table → add one (Plan mode step 2). Never rename the plan.
2. Read `<archify>/SKILL.md` + each type's `schemas/` and `examples/` entry — archify wins on JSON shape.
3. Per row, write `{dir}/<type>.json` — re-render: **edit** it so unchanged ids/layout stay. Draw §6 **After** only; frames = the repo's real folders; mark new/changed parts. `meta.quality_profile: "showcase"`.
4. `node <archify>/bin/archify.mjs finalize <type> {dir}/<type>.json {dir}/<type>.html --quality showcase --json` (+ `--repo-root <repo>` when drawn from code; existing `<type>.html` → + `--out-dir {dir}/review-<n>`). Non-zero → fix, rerun. Never report a failing render as done.
5. Copy this folder's `index.html` to `{dir}/index.html`, fill: `{Plan title}` ← `name`, `{Plan overview}` ← `overview`, `TABS` ← table rows `{ type, why }`, `FILES` ← one `{ path, status, note }` per file the plan creates / changes / removes (`create` / `change` / `delete`, full repo path, note = its annotation; none → `[]`).
6. Publish `file_path: {dir}/index.html`, `files: { "<type>.html": "{dir}/<type>.html", … }`, removed type → `null`.
   - No `diagram.artifact` → new (`icon: diagram`), write the URL to frontmatter.
   - Set → republish (later conversation: `Artifact read` it, then publish with `url`). Refused → publish new, replace URL, say so.
7. Report: URL, types rendered, "automated checks only, not visually reviewed".

Plan changed later → edit it, Build again: same `dir`, same JSON files, same URL.

## Template

Frontmatter, add:

```yaml
diagram:
  artifact: ""                     # filled by first Build
  dir: .archify/{plan}/            # {plan} = plan file name minus -diagram.md (or .md); under the cwd
```

§6, after **After**:

```markdown
### Diagram (archify)
| Type | Why | Source |
|---|---|---|
| workflow | {what this view shows} | .archify/{plan}/workflow.json |
```
