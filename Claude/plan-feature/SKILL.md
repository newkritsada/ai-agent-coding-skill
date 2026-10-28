---
name: plan-feature
description: Plan a feature in three gated stages — BE diagram plan, FE diagram plan (both via plan-diagram-archify, reviewed until "approve"), then a summary plan holding the branch stack and checkpoint commits for build-stack. Suggests a compact and returns to plan mode between stages. Manual launcher — invoke with /plan-feature.
disable-model-invocation: true
---

# Plan feature

## Uses

Load a skill by name: read `~/.claude/skills/<name>/SKILL.md`.

1. `/plan-diagram-archify` — BE, FE stages
2. `/plan-pattern` — summary stage
3. `/clean-architecture` — **Pick** only — placement while planning
4. `/commit-checkpoint` — §7 stack

Plans only — never app code. Building is `/build-stack {summary plan}`.

## Stages

| # | Stage | Follow | File (plans folder) |
|---|---|---|---|
| 1 | BE | `/plan-diagram-archify` | `{topic}_{name}-be.diagram.md` |
| 2 | FE | `/plan-diagram-archify` | `{topic}_{name}-fe.diagram.md` |
| 3 | Summary | `/plan-pattern` | `{topic}_{name}.summary.md` |

`{topic}` = the plan group, `{name}` = a short kebab name you suggest in the first grilling round. Enhance each base only by the file name above and frontmatter:

```yaml
flow:
  stage: be          # be | fe | summary
  review: open       # open | approved
```

While planning BE / FE, apply `/clean-architecture` **Pick** to §3–§4 — placement only, no code.

## Start / resume

| User gives | Do |
|---|---|
| a feature description | new group → BE |
| a topic / file name, or "next" | read state from the group's three files only → **Checkpoint** → continue |

| Files | Stage |
|---|---|
| no BE / BE `open` | BE / BE review |
| BE approved, no FE / FE `open` | FE / FE review |
| FE approved, no summary / summary `open` | Summary / summary review |
| summary approved | done → `/build-stack {summary path}` |

"next" after a compact and this text is gone → read `~/.claude/skills/plan-feature/SKILL.md` first.

## Diagram stage (BE, FE)

1. In plan mode, run the base's **Plan** mode. BE: FE only as far as the API must expose. FE: read the BE plan first, cite its endpoints / contracts in §2 **Constraints**, never re-plan BE.
2. `ExitPlanMode` → the base's **Build** mode (render the Artifact) → **Checkpoint**.
3. Feedback → edit plan → render again (same URL) → **Checkpoint**. Until the user says "approve".
4. "approve" → `review: approved` → **Handoff**.

## Summary stage

1. In plan mode, read both diagram plans. Follow plan-pattern:
   - §2 **Current** = what BE and FE decided, citing their paths. **To do** adds integration: API client, shared contract types, env / config, end-to-end checks.
   - §3–§5 = both plans' files + integration files.
   - §7 = the stack per `/commit-checkpoint`, template below. Todos = one per commit, `id: b1-c1`. Grill on branch boundaries and `Needs` — fewer Needs, more branches build in parallel. Under the stacks, the **Build order** table per `/commit-checkpoint`, so the user sees what runs in parallel and what waits before approving.
2. `ExitPlanMode`, review until "approve" → `review: approved` → **Handoff**. Never build.

```markdown
## 7. Steps

### Stack · {repo} · base `{default branch}`
| # | Branch | Parent | Needs | Review focus | Files | Status |
|---|---|---|---|---|---|---|
| B1 | `{branch}-1-structure` | `{default}` | — | structure | ~{n} | pending |
| B2 | `{branch}-2-domain` | B1 | B1 | business rules | ~{n} | pending |

#### B1 — structure
| # | Commit message | Checkpoint | Contains | Status |
|---|---|---|---|---|
| B1-C1 | {message} | init folder structure | `{path}`, `{path}` | pending |
```

One **Stack** per repo (BE, FE). `Contains` = real paths or globs. Status is filled by build-stack.

## Checkpoint

Print at stage start, after every render, on approve, on resume:

```
Checkpoint · {topic}
- [x] BE       {abs path} · approved · {artifact URL}
- [ ] FE       {abs path} · open · {artifact URL}
- [ ] Summary  —
Now: {stage · step}   Next: {what the user does}
```

## Handoff

After "approve":

1. Print **Checkpoint**, then the compact command filled in, ready to paste — optional; the user runs it, you can't:
   ```
   Suggest: /compact Keep for plan-feature: topic {topic}; next stage {FE | Summary | build}; plans {abs path per approved plan}; artifacts {URLs}. Drop diagram JSON, grilling and review chatter.
   ```
2. `EnterPlanMode`, then wait. "next" → next stage. After the summary: wait for `/build-stack {summary path}`.
