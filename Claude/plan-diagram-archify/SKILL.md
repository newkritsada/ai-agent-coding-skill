---
name: plan-diagram-archify
description: Plan a feature with plan-pattern plus an archify diagram suggestion, then render the plan's flow as archify diagrams in one tabbed Artifact that later runs update in place. Use instead of /plan-clean-structure when the goal is a diagram, not code. Manual launcher — invoke with /plan-diagram-archify.
disable-model-invocation: true
---

# Plan → archify diagram

Never writes application code — building code is `/plan-clean-structure`'s job.

## Mode

| Context | Mode |
|---|---|
| Plan mode active, or args describe a feature | **Plan** |
| Not in plan mode, plan path given or findable | **Build** |

Find the plan like `../plan-clean-structure/SKILL.md`: given path → last `Plan saved at:` → newest `*.plan.md` under `.claude/plans/`.

## archify check (both modes)

archify = `~/.claude/skills/archify/` or `.claude/skills/archify/` (`SKILL.md` + `bin/archify.mjs`). Missing →

1. Plan mode → no install (read-only). Add to §2 **Constraints**: `prereq: npx skills add tt-a1i/archify -g`.
2. Otherwise → show `npx skills add tt-a1i/archify -g`, ask **once**, install (the `skills` CLI needs Node ≥ 20.12 — on an older default, prefix `PATH` with a newer nvm Node), then `node <archify>/bin/archify.mjs doctor`. Declined → Plan mode: prereq line as above. Build mode: stop and say so.

## Plan mode

1. Read and follow `../plan-pattern/SKILL.md` fully — workflow, grilling, all 8 sections.
2. Pick 1–3 archify types from the table below; first = primary. Ask in grilling only if two types tie.
3. Add the §6 sub-heading and frontmatter block from the template. `{topic}` = plan file name without `.plan.md`.
4. End with `Plan saved at: …`. Render waits for Build mode.

| Plan signal | archify type |
|---|---|
| §6 flow with steps / branches / exits | `workflow` (default primary) |
| calls across API → service → DB / external over time | `sequence` |
| §3–§4 span several modules, services, storage | `architecture` |
| data moves / transforms / PII | `dataflow` |
| entity status changes, retries | `lifecycle` |
| migration / entity / relation changes | `erd` |
| new classes, interfaces, ports | `class` |
| §3 folder tree is the point | `tree` |
| phased rollout across §7 | `timeline` |
| latency / step-cost breakdown | `waterfall` |

## Build mode

1. Read the plan: §6 **After**, §3–§4, the `### Diagram (archify)` table, frontmatter `diagram:`. No table → add one first (Plan mode steps 2–3).
2. Read `<archify>/SKILL.md` and, per type, its `schemas/` entry and `examples/` file — archify's rules win on JSON shape.
3. Per row, write `{dir}/<type>.json` — first render: new; later: **edit** the existing file so unchanged nodes keep their ids and layout.
   - Draw the planned (After) flow only. Frames/groups = the repo's real folder names. New or changed parts say so in label or note.
   - `meta.quality_profile: "showcase"`.
4. `node <archify>/bin/archify.mjs finalize <type> {dir}/<type>.json {dir}/<type>.html --quality showcase --json` (+ `--repo-root <repo>` when drawn from code). Re-render of an existing `<type>.html` → add `--out-dir {dir}/review-<n>` (archify refuses to reuse browser evidence; the HTML path stays fixed). Non-zero → fix the failed gate, rerun the full command. Never report a failing render as done.
5. Copy `index.html` from this skill folder to `{dir}/index.html`; replace both `{Plan title}` with the plan title and set `TABS` to the table's rows in order (`type`, `why`).
6. Publish — `file_path: {dir}/index.html`, `files: { "<type>.html": "{dir}/<type>.html", … }`:
   - `diagram.artifact` empty → first publish (`icon: diagram`); write the URL into frontmatter.
   - Set → same conversation: republish same `file_path`. Later conversation: `Artifact read` the url, then publish with `url`.
   - Type removed from the table → `"<type>.html": null`.
   - Publish refused for that url (not owner/writer) → publish new, replace the URL, say so.
7. Report: artifact URL, types rendered, "automated checks only, not visually reviewed", then `Plan saved at: …`.

## Update

New context or a changed plan after a build → edit the plan (plan-pattern rules), then Build mode again. Same `dir`, same `<type>.json` files, same URL — never a new artifact while the old one is writable.

## Template

Frontmatter (add under `isProject`):

```yaml
diagram:
  artifact: ""                # filled by first Build
  dir: .archify/{topic}/      # relative to the repo root; Artifact sources must be under the cwd
```

§6, after **After**:

```markdown
### Diagram (archify)
| Type | Why | Source |
|---|---|---|
| workflow | {one line: what this view shows} | .archify/{topic}/workflow.json |
| sequence | {one line} | .archify/{topic}/sequence.json |

Prereq: archify — `npx skills add tt-a1i/archify -g`   ← only when missing
```
