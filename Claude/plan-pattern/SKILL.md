---
name: plan-pattern
description: Plan structure for .plan.md files (Plan mode, /plan, or user asks to plan/design/break down work). Defines frontmatter, 8 fixed sections, and todos. Always runs a mandatory `grilling` interview before filling the plan. Project-agnostic.
---

# Plan pattern

Defines **plan file structure only**. Stack rules live in the repo's `AGENTS.md` / `CLAUDE.md`.

## Workflow — always, no exceptions

1. **Write** the plan file with only `## 1. Understanding` (bulleted restatement of the request) and an empty `## 8. Open questions`.
2. **Invoke the `grilling` skill.** One question at a time, each with a recommended answer. Explore the codebase instead of asking whatever the code can answer.
   - Answered → fold into its section (prereqs → §2, file effects → §3–§5, behavior/edge cases → §6, sequencing → §7).
   - User can't decide, or asks a question back → park the question **plus the context that blocked it** in §8; continue other branches.
   - Later resolved → delete the §8 entry. §8 is a live queue, not a log.
3. **Fill** §2–§7. If §8 is still non-empty, grill again on only those items.

## Rules

- All 8 headings always render, in order. Empty ones get `None` — never delete a heading.
- §7 maps 1:1 to frontmatter `todos`. No orphan todos, no unlisted steps.
- **Reading a plan: skip the fenced mermaid block, read the prose flow.** The diagram is human-only and carries nothing the prose omits.
- Compact: tables, bullets, paths. Concrete names — no "etc." or "similar to existing". Complex plans get more *rows*, not longer *sentences*.

## Template

````markdown
---
name: {Plan title}
overview: {One sentence — what, scope, outcome. Never repeated in the body.}
todos:
  - id: {kebab-id}          # one per §7 step
    content: {actionable one-liner}
    status: pending
isProject: false
---

# {Plan title}

## 1. Understanding
{Bulleted restatement of what the user wants, so a misread is caught early.
Note any assumption made, and any request that couldn't be honored as stated.}

## 2. Requirements
{Prereqs this plan depends on: deps, data, config, access. Names, paths, types.
Not implementation steps — those are §7.}

## 3. Files to create
{ASCII tree of new paths, grouped logically. Mark the entry/orchestrator file.}

## 4. Files to change
- `{path}` — {what changes, one line}

## 5. Files to remove
- `{path}` — {why}

## 6. How it works

<!-- flowchart below is human-only — skip when reading this plan -->
```mermaid
flowchart TD
  subgraph {file or responsibility}
    A[Start] --> B{condition?}
    B -->|no| X[Exit]
    B -->|yes| C[Step]
  end
```

**Prose flow** (source of truth):
1. {What runs, in what order, under what condition — not line-by-line code.}

### {Non-obvious rule — retries, idempotency, naming, completion criteria}
{Only when such a rule exists.}

## 7. Steps
1. {Foundation first, then dependents. Dependency-safe order.}

## 8. Open questions
| Question | Context / blocker |
|---|---|
| {parked question} | {why it couldn't be answered} |

{`None` once empty.}
````
