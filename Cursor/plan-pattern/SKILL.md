---
name: plan-pattern
description: Plan structure and pattern for .plan.md files (Plan mode, /plan, or user asks to plan). Use when writing plans — frontmatter shape, required sections, section order, todos. Project-agnostic; adapt content to the repo.
---

# Plan pattern

## When to use

Plan mode, `/plan`, or the user asks to plan / design / break down work.

This skill defines **plan file structure only**. Read the repo’s `AGENTS.md` or local conventions separately for stack-specific rules.

## Plan file format

Cursor plans use **YAML frontmatter** + **markdown body**.

```yaml
---
name: {Plan title}
overview: {One sentence — what, scope, outcome}
todos:
  - id: {kebab-id}
    content: {actionable one-liner}
    status: pending
isProject: false
---

# {Plan title}

## What is needed
...

## Files to create
...

## How the flow works
...

## Implementation order
...
```

**Frontmatter rules**

- `overview` — single sentence; do not repeat as a body section.
- `todos` — one entry per major step in **Implementation order**; `id` = kebab-case; `status: pending` for new plans.

## Required body sections

Use this order. Omit a section only when it truly does not apply.

| # | Section | Purpose |
|---|---------|---------|
| 1 | **What is needed** | Prerequisites this plan depends on (deps, data, config, access) |
| 2 | **Files to create** | New paths + existing paths to change |
| 3 | **How the flow works** | Diagram + rules for behavior and edge cases |
| 4 | **Implementation order** | Numbered, dependency-safe build sequence |

**Optional body sections** — after **How the flow works**, before **Implementation order**, only when relevant:

- Named constants / shared definitions
- Completion criteria (when is the work done?)
- Error, retry, or state rules

## Section guidelines

### What is needed

- Use `###` subsections for each prerequisite type (only what applies).
- Be concrete: names, paths, types — not “add necessary fields”.
- Do not list implementation steps here; those belong in **Implementation order**.

### Files to create

- ASCII tree for **new** files, grouped logically.
- **Also extend / modify** — bullet list: path + one line on what changes.
- Call out the main entry/orchestrator file when the plan has multi-step logic.

### How the flow works

- **Mermaid `flowchart TD`** when the work has multiple steps, branches, or async paths.
- **Two diagrams when changing existing behavior: “Before (current flow)” then “After (planned flow)”** — so the reader sees the change as a diff. Keep node IDs and layout identical where the flow is unchanged; mark added/modified nodes with `:::changed` (dashed). Greenfield work: skip Before, render only After.
- Use `subgraph` per file, layer, or responsibility.
- Under the diagram, `###` subsections for non-obvious rules (retries, completion, naming, idempotency).
- Describe **what runs, in what order, under what conditions** — not line-by-line implementation.

### Implementation order

- Numbered list, dependency-safe (foundation before dependents).
- Each item should map to one or more frontmatter `todos`.

## Quality bar

| Do | Don’t |
|----|-------|
| One overview sentence in frontmatter | Vague “implement feature X” |
| Concrete paths and identifiers | “etc.” / “similar to existing” |
| Mermaid for multi-step flows | Prose-only flow when a diagram would clarify |
| Todos match implementation order | Orphan todos with no section backing |
| Optional sections only when needed | Boilerplate sections on every plan |

## Template

Copy structure from [reference.md](reference.md).
