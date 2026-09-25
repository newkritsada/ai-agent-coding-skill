---
name: plan-pattern
description: Plan structure for .plan.md files (Plan mode, /plan, or user asks to plan/design/break down work). Defines frontmatter, 8 fixed sections, and todos. Always runs a mandatory `grilling` interview before filling the plan. Project-agnostic.
---

# Plan pattern

Plan **file structure only**. Stack rules live in the repo's `AGENTS.md` / `CLAUDE.md`.

## Workflow — always, no exceptions

1. **Write** the plan file as `{kebab-topic}.plan.md` — never a bare `.md`. Directory: the one the repo or user already uses for plans, else `.claude/plans/` in the repo. Plan mode assigned a path ending in plain `.md` → write there while in Plan mode, then the moment it exits `mv` it to `{kebab-topic}.plan.md` and fix the last line. Start with §1 Requirement (user's needs, short list), §2 Understanding with only **Current** filled from codebase exploration, §8 empty.
2. **Grill** — invoke the `grilling` skill. One question at a time, each with a recommended answer. Never ask what the code can answer.
   - Every question → one row in §8 (question + one-line answer).
   - Answered → fold into its section: what/how/scope → §2, file effects → §3–§5, behavior/edge cases → §6, sequencing → §7.
   - Undecided or user asks back → §8 row marked **open** with the blocker; continue other branches. Resolved later → replace the marker.
3. **Fill** §2–§7. Open §8 rows → grill again on those only.
4. **Report** — final message ends with the full path: `Plan saved at: /path/to/repo/feature.plan.md`. Never finish without it, and never with a path that doesn't end in `.plan.md`. Building it is `/plan-clean-structure`'s job.

## Rules

- All 8 headings render, in order. Empty → `None`. Never delete a heading.
- §2 has three fixed parts: **Current** (how the affected flow works today), **To do** (what + how), **Constraints**. **To do** is derived only from §1 + §8 — no scope without a source. **Current** is the short read; §6 Before is the full diagram — don't duplicate.
- §3–§5 share one ASCII-tree shape; §4/§5 annotate each leaf (`— what changes` / `— why removed`).
- §6 mermaid **Before**/**After** *is* the flow description — complete enough to stand alone (every step, branch, exit named). Same subgraph/node IDs where unchanged; added/modified nodes `:::changed`. Greenfield: Before = `None`.
- §6 diagram style — always this shape:
  - `graph TB`; one `subgraph` per layer or responsibility, label `"{emoji} {Name}"`, `direction TB` inside. Nodes are the real files/functions/steps in the code's own names.
  - Every edge between subgraphs is labeled: `-->|calls|`, `-->|depends on|`, `-->|reads|`; dashed `-.->|implements|` for interface/async/optional. Branches: `{cond?}` diamond with `|yes|`/`|no|`. Edges point downward only — no back-edges; a return value is implied by the call.
  - Color every subgraph with `style` from one palette: 🌐 Presentation `#87ceeb` · ⚙️ Application `#98fb98` · 💎 Domain `#ffd700` · 🔧 Infrastructure `#dda0dd` · 🔌 External `#f5deb3` — `stroke:#333,stroke-width:2px`. Non-layered code: pick by role (entry → blue, logic → green, core rules → gold, I/O → purple).
  - Highlight change: `classDef changed stroke:#ff6347,stroke-width:3px` on added/modified nodes; a subgraph whose whole content is new gets `stroke:#ff6347,stroke-width:3px` in its `style`.
- §7 ↔ frontmatter `todos` 1:1. No orphan todos, no unlisted steps.
- File name ends in `.plan.md`; last line of the file is its own absolute path (`Plan saved at: …`) so the plan can be found from any context.
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
{`None` for greenfield — no diagram then.}

```mermaid
graph TB
    subgraph Presentation["🌐 {Presentation / entry}"]
        direction TB
        P1[{Controller.method}]
    end

    subgraph Application["⚙️ {Application / logic}"]
        direction TB
        A1[{UseCase.execute}]
        A2[{Port / Interface}]
    end

    subgraph Infrastructure["🔧 {Infrastructure / I/O}"]
        direction TB
        I1[{Repository}]
    end

    P1 -->|calls| A1
    A1 -->|depends on| A2
    I1 -.->|implements| A2

    style Presentation fill:#87ceeb,stroke:#333,stroke-width:2px
    style Application fill:#98fb98,stroke:#333,stroke-width:2px
    style Infrastructure fill:#dda0dd,stroke:#333,stroke-width:2px
```

### After (planned flow)

```mermaid
graph TB
    subgraph Presentation["🌐 {Presentation / entry}"]
        direction TB
        P1[{Controller.method}]
    end

    subgraph Application["⚙️ {Application / logic}"]
        direction TB
        A1[{UseCase.execute}]
        A3{condition?}:::changed
        A2[{Port / Interface}]
    end

    subgraph Domain["💎 {Domain / core rules}"]
        direction TB
        D1[{Entity / rule}]:::changed
    end

    subgraph Infrastructure["🔧 {Infrastructure / I/O}"]
        direction TB
        I1[{Repository}]
    end

    P1 -->|calls| A1
    A1 --> A3
    A3 -->|no| X[{Exit: error}]
    A3 -->|yes| D1
    A1 -->|depends on| A2
    I1 -.->|implements| A2

    style Presentation fill:#87ceeb,stroke:#333,stroke-width:2px
    style Application fill:#98fb98,stroke:#333,stroke-width:2px
    style Domain fill:#ffd700,stroke:#ff6347,stroke-width:3px
    style Infrastructure fill:#dda0dd,stroke:#333,stroke-width:2px
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
Plan saved at: {/absolute/path/to/this/file.plan.md}
