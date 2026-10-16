---
name: plan-feature-flow
description: Plan a large feature in three stages sharing one plan group — BE plan and FE plan via plan-diagram-archify (diagram Artifact, team review until "review done"), then a final plan-phased-mr plan that integrates FE with BE. Prints a checkpoint of the current state and hands off between stages via /compact or /clear. Manual launcher — invoke with /plan-feature-flow.
disable-model-invocation: true
---

# Plan feature flow

Plans only, every stage — never app code. Building is later: `/plan-phased-mr {group}_final.md`.

## Stages

| # | Stage | Follow | Plan file | Scope |
|---|---|---|---|---|
| 1 | BE | `../plan-diagram-archify/SKILL.md` | `{group}_be-diagram.md` | backend only |
| 2 | FE | `../plan-diagram-archify/SKILL.md` | `{group}_fe-diagram.md` | frontend only, guided by the BE plan |
| 3 | Final | `../plan-phased-mr/SKILL.md` | `{group}_final.md` | BE + FE + integration, no diagram |

Enhance each base plan only by: topic = `be` / `fe` / `final`, and frontmatter add:

```yaml
flow:
  stage: be        # be | fe | final
  review: open     # open | done — be / fe only
```

## Start / resume

| Invoked with / user says | Do |
|---|---|
| a feature description | new group (plan-pattern **File location**) → BE stage |
| a group name, or "next" | read state → print **Checkpoint** → continue there |

State — open only the group's three files, never scan the plans folder:

| Files | Stage |
|---|---|
| no BE | BE |
| BE `review: open` | BE review |
| BE done, no FE | FE |
| FE `review: open` | FE review |
| FE done, no final | Final |
| final exists | done |

"next" after a compact and this skill's text is gone → read `~/.claude/skills/plan-feature-flow/SKILL.md` first.

## Diagram stage (BE, FE)

1. Not in plan mode → `EnterPlanMode`. Run the base's **Plan** mode, scoped per **Stages**.
   - BE: FE only as far as what the API must expose.
   - FE: read `{group}_be-diagram.md` first; §2 **Constraints** cites it and the endpoints / contracts FE uses. Re-read it when an FE decision depends on BE. Never re-plan BE.
2. `ExitPlanMode` — ask the user to approve with **auto mode**. Approved → the base's **Build** mode (render the Artifact) → **Checkpoint**.
3. Review loop — team feedback → edit the plan → Build again (same URL) → **Checkpoint**. Repeat until the user says "review done".
4. "review done" → set `flow.review: done` → **Checkpoint** → **Handoff**.

## Final stage

1. `EnterPlanMode`. Read both diagram plans. Run plan-phased-mr **Plan** mode:
   - §2 **Current** = what the BE and FE plans decided, citing their paths. **To do** adds the FE ↔ BE integration: API client, shared contract types, env / config, end-to-end checks.
   - §3–§5 = union of both plans' files + integration files.
   - No archify, no Artifact.
2. `ExitPlanMode` — approval ends the flow; never build. → **Checkpoint** (all done) + build command `/plan-phased-mr {group}_final.md`.

## Checkpoint

Print at a stage start, after every render, on "review done", on resume:

```
Checkpoint · {group}
- [x] BE     {abs path} · review done · {artifact URL}
- [ ] FE     {abs path} · review open · {artifact URL}
- [ ] Final  —
Now: {stage · step}   Next: {what the user does}
```

## Handoff

Only after "review done". Print both options with exact commands — the user types the one they pick; Claude can't run either.

| Option | Command | Then |
|---|---|---|
| Compact — keeps a summary | `/compact Keep for plan-feature-flow: group {group}; next stage {FE / Final}; plans {abs paths}; artifact URLs {URLs}. Drop diagram JSON and review chatter.` | say "next" |
| Clear — fresh context; plan files hold the state | `/clear` | `/plan-feature-flow {group}` |
