---
name: plan-pattern
description: Plan structure for plan files (Plan mode, /plan, or user asks to plan/design/break down work). Defines file naming with a group prefix for related plans, frontmatter, 8 fixed sections, and todos. Always runs a mandatory `grilling` interview before filling the plan. Project-agnostic.
---

# Plan pattern

Plan **file structure only**. Stack rules live in the repo's `AGENTS.md` / `CLAUDE.md`.

## Workflow — always, no exceptions

1. **Write** the plan file per **File location**. Start with §1 Requirement (user's needs, short list), §2 Understanding with only **Current** filled from codebase exploration, §8 empty.
2. **Grill** — follow `../grilling/SKILL.md`.
   - Every question → one row in §8 (question + one-line answer).
   - Answered → fold into its section: what/how/scope → §2, file effects → §3–§5, behavior/edge cases → §6, sequencing → §7.
   - Undecided or user asks back → §8 row marked **open** with the blocker; continue other branches. Resolved later → replace the marker.
3. **Fill** §2–§7. Open §8 rows → grill again on those only.
4. **Report** — final message ends with `Plan saved at: /abs/path/to/{group}--{topic}.md`. Never finish without it. Planning ends here; building is a separate step (**Using a plan**).

## File location

Related plans share a name prefix so they sort together in the plans folder.

- Folder: the default plans folder (where Plan mode puts plans). Name: `{group}--{topic}.md`, both kebab-case.
- `{topic}` = this plan's subject. `{group}`:

| Situation | `{group}` |
|---|---|
| First plan in this session | short name of the overall work (often = topic) |
| Another plan in this session | this session's group — unless the user says it's unrelated |
| User names a plan file from another session | that file's group: the part before `--` (no `--` → its whole name) |

- Never list or scan the plans folder to pick a group — only this session's plans or a file the user names.
- Plan mode assigned another name → write there while in Plan mode; once it exits, `mv` to `{group}--{topic}.md` in the same folder and fix the last line.
- `.plan.md` only on request — user asks for one → write `{group}--{topic}.plan.md` then, where they say (else the repo's `.claude/plans/`).

## Using a plan

For skills that read or build an existing plan.

1. **Find** — path or file name the user gave (bare name → the plans folder) → else this session's last `Plan saved at:` → else ask for the file name.
2. **Build** (only when the calling skill builds code) — execute §7 in order, updating each frontmatter todo `status` as you go.
3. End with `Plan saved at: /abs/path`.

## Rules

- All 8 headings render, in order. Empty → `None`. Never delete a heading.
- §2 has three fixed parts: **Current** (how the affected flow works today), **To do** (what + how), **Constraints**. **To do** is derived only from §1 + §8 — no scope without a source. **Current** is the short read; §6 Before is the full diagram — don't duplicate.
- §3–§5 share one ASCII-tree shape; §4/§5 annotate each leaf (`— what changes` / `— why removed`).
- §6 mermaid **Before**/**After** *is* the flow description — complete enough to stand alone (every step, branch, exit named). Same subgraph/node IDs where unchanged; added/modified nodes `:::changed`. Greenfield: Before = `None`.
- §6 diagram style — always this shape:
  - `graph TB`; **frames follow the project's real structure** — one `subgraph` per folder / module / package the flow passes through, labeled with its actual path (`"{emoji} src/routes"`, `"{emoji} internal/billing"`), `direction TB` inside. Never invent architecture frames (Presentation, Application, Domain…) the repo doesn't have; use them only if they are the repo's own folder names. Nodes are the real files/functions/steps in the code's own names.
  - Every edge between subgraphs is labeled: `-->|calls|`, `-->|depends on|`, `-->|reads|`, `-->|writes|`; dashed `-.->|implements|` for interface/async/optional. Branches: `{cond?}` diamond with `|yes|`/`|no|`. Edges point downward only — no back-edges; a return value is implied by the call.
  - Color each frame by the **role** of that folder, from one palette: 🌐 entry `#87ceeb` · ⚙️ logic `#98fb98` · 💎 core rules `#ffd700` · 🔧 I/O `#dda0dd` · 🔌 external `#f5deb3` — `stroke:#333,stroke-width:2px`. Emoji matches the color.
  - Highlight change: `classDef changed stroke:#ff6347,stroke-width:3px` on added/modified nodes; a subgraph whose whole content is new gets `stroke:#ff6347,stroke-width:3px` in its `style`.
- §7 ↔ frontmatter `todos` 1:1. No orphan todos, no unlisted steps.
- Last line of the file is its own absolute path (`Plan saved at: …`) so the plan can be found from any context.
- Compact: tables, bullets, paths. Concrete names — no "etc." / "similar to existing". Complex plans get more *rows*, not longer *sentences*.

## Template

`{…}` = placeholder. File starts with:

```yaml
---
name: {Plan title}
overview: {One sentence — what, scope, outcome. Never repeated in the body.}
todos:
  - id: {kebab-id}          # one per §7 step
    content: {actionable one-liner}
    status: pending
isProject: false
---
```

---

# {Plan title}

## 1. Requirement
{One bullet per need, in the user's terms. Readable on its own.}

## 2. Understanding
{Three fixed parts, bullets only. A misread must be catchable here.}

**Current** — how the affected flow/logic works today, from reading the code. `None` for greenfield.
- {entry point} → {step} → {step} → {exit} — one chain per path, in the code's own names
- {file/function}: {logic that matters to this plan — condition, data shape, side effect}

**To do** — what changes and how. Every bullet traces to a §1 need or §8 answer.
- {§1 need / §8 answer} → {what: concrete change} — {how: approach, one line}

**Constraints** — scope boundaries, assumptions, prereqs (deps, data, config, access).
- {out of scope / assumption / prereq}

## 3. Files to create
{ASCII tree of new paths, grouped logically. Mark the entry/orchestrator file.}

```
src/
├── feature/
│   ├── index.ts        ← entry
│   └── helper.ts
└── feature.test.ts
```

## 4. Files to change
{Same tree; each leaf `— what changes, one line`.}

```
src/
├── app.ts              — register feature route
└── config.ts           — add FEATURE_FLAG env
```

## 5. Files to remove
{Same tree; each leaf `— why`.}

```
src/
└── legacy/
    └── old-feature.ts  — replaced by src/feature/
```

## 6. How it works

### Before (current flow)
{`None` for greenfield — no diagram then. Frames = the repo's real folders; names below are placeholders.}

```mermaid
graph TB
    subgraph Routes["🌐 {src/routes}"]
        direction TB
        R1[{orders.route.ts: POST /orders}]
    end

    subgraph Services["⚙️ {src/services}"]
        direction TB
        S1[{createOrder}]
    end

    subgraph Db["🔧 {src/db}"]
        direction TB
        D1[{orderRepo.insert}]
    end

    R1 -->|calls| S1
    S1 -->|writes| D1

    style Routes fill:#87ceeb,stroke:#333,stroke-width:2px
    style Services fill:#98fb98,stroke:#333,stroke-width:2px
    style Db fill:#dda0dd,stroke:#333,stroke-width:2px
```

### After (planned flow)

```mermaid
graph TB
    subgraph Routes["🌐 {src/routes}"]
        direction TB
        R1[{orders.route.ts: POST /orders}]
    end

    subgraph Services["⚙️ {src/services}"]
        direction TB
        S1[{createOrder}]
        S2{in stock?}:::changed
    end

    subgraph Pricing["💎 {src/pricing}"]
        direction TB
        P1[{calcTotal}]:::changed
    end

    subgraph Db["🔧 {src/db}"]
        direction TB
        D1[{orderRepo.insert}]
    end

    R1 -->|calls| S1
    S1 -->|calls| P1
    S1 --> S2
    S2 -->|no| X[{Exit: OutOfStockError}]
    S2 -->|yes · writes| D1

    style Routes fill:#87ceeb,stroke:#333,stroke-width:2px
    style Services fill:#98fb98,stroke:#333,stroke-width:2px
    style Pricing fill:#ffd700,stroke:#ff6347,stroke-width:3px
    style Db fill:#dda0dd,stroke:#333,stroke-width:2px
    classDef changed stroke:#ff6347,stroke-width:3px
```

### {Non-obvious rule}
{Optional — only for a rule the flow can't show: retry policy, idempotency, naming convention, "done when…" criteria. Omit otherwise.}

## 7. Steps
1. {Foundation first, then dependents. Dependency-safe order.}

## 8. Grilling Q&A
{One row per question asked — the record the user rechecks and can re-answer.}

| Question | Answer |
|---|---|
| {question, compressed} | {answer, one line} |
| {parked question} | **open** — {context / blocker} |

---
Plan saved at: {/absolute/path/to/{group}--{topic}.md}
