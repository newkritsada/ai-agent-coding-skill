---
name: plan-phased-mr
description: Plan a large feature as phases — one independent MR per phase (<30 files, cap 50), each with a planned list of self-contained commits — then build one phase at a time, stop for review, and on "commit" split it into those commits. Manual launcher — invoke with /plan-phased-mr.
disable-model-invocation: true
---

# Plan phased MR

> **Every MR merges alone. Every commit builds alone.**

## Modes

| Invoked with | Mode |
|---|---|
| a feature / requirement | **Plan** |
| a `.plan.md` path, "build", "continue", "commit" | **Build** — plan file found like `../plan-clean-structure/SKILL.md` finds it |

## Plan

1. Follow `../plan-pattern/SKILL.md` fully — file name, grilling, 8 sections, last line. This skill changes only §7 and the todos.
2. Estimate changed files from §3–§5. Total ≤ 30 → one phase. More → split by the phase rules.
3. Grill on the split too: phase boundaries, each cherry-pick, anything shared between phases → §8 rows.
4. Write §7 with the template below. Todos = one per commit, `id: p1-c1`, `content:` the commit message.

## Phase rules

| Rule | Why |
|---|---|
| 1 phase = 1 MR = 1 branch off the default branch (the repo's MR target), named per repo convention. | Each MR reviews and merges on its own. |
| **Never branch a phase off another phase.** | A chain: one review fix forces a rebase of every MR after it, and each diff shows its parents' commits. |
| Target < 30 files changed, cap 50. Over → split the phase. | A reviewer reads it in one sitting. |
| Order: foundation (schema, entities, ports, shared types) → features → wiring / cleanup. | Later phases need only early, stable commits. |
| Phase needs an earlier phase's commit → cherry-pick it; list it under **Cherry-picks** with its id. | Dependency is explicit and one commit wide. |
| Shareable commits go first in their phase — small, stable, nothing else mixed in. | Picks apply cleanly and rarely change. |
| > 2 picks, or the source keeps changing in review → wait for that MR to merge, branch off the updated default branch. | Too many picks is a chain in disguise. |
| A picked commit changes in review → re-pick it in every phase that lists it. | Phases stay in sync. |
| The source MR merges → rebase the dependent phase onto the default branch. | Git drops the identical picked commit. |

## Commit rules

| Rule | Why |
|---|---|
| Builds, lints, tests pass on its own — on its branch and cherry-picked alone onto the default branch (plus its listed picks). | Anyone can pick it without errors or missing pieces. |
| Signature / rename change → every caller and their tests in the same commit. | No commit leaves a broken call site. |
| Schema change → migration + entity + mapping together. | Code and database never disagree. |
| New code ships with its tests — no later "add tests" commit. | Each commit proves itself. |
| Code may be unused until a later commit, never broken until one. | Unused builds; broken doesn't. |
| One concern per commit, ~≤ 10 files. Message in the repo's `git log` style. | Reviewable commit by commit. |
| Every file in exactly one commit of its phase where possible. | Splitting on "commit" stays mechanical. |

## §7 template

```markdown
## 7. Steps

### Phase 1 — {title} · MR 1/{N}
- **Branch:** `{repo convention}` from `{default branch}`
- **Cherry-picks:** None
- **Files:** ~{n} (target < 30, cap 50)

| # | Commit message | Contains | Files | Status |
|---|---|---|---|---|
| P1-C1 | {message} | `{path}`, `{path}`, `{spec path}` | {n} | pending |
| P1-C2 | {message} | `{path}`, `{spec path}` | {n} | pending |

### Phase 2 — {title} · MR 2/{N}
- **Branch:** `{repo convention}` from `{default branch}`
- **Cherry-picks:** P1-C1 `{sha once committed}` — {why this phase needs it}
- **Files:** ~{n} (target < 30, cap 50)

| # | Commit message | Contains | Files | Status |
|---|---|---|---|---|
| P2-C1 | {message} | `{path}`, `{spec path}` | {n} | pending |
```

`Contains` is the staging list on "commit" — real paths or globs, not descriptions. Status: `pending` → `review` → `committed {sha}`.

## Build

Code style: pick the skill with `../plan-clean-structure/SKILL.md`'s scope rule and follow it — read it, don't run it (it builds all of §7 with no stops).

1. **Start phase** — `git fetch`; `git switch -c {branch} origin/{default}`; `git cherry-pick {sha}` per listed pick. Conflict → stop and ask.
2. **Build** every commit of the phase, in table order, uncommitted. Rows → `review`, todos → `in_progress`.
3. **Verify** the whole phase — the repo's typecheck / lint / build + tests for touched code. Fail → fix before stopping.
4. **Stop** — report the phase's commit table (id, message, files each will hold), `git status --short`, checks run + result. Don't start the next phase.
5. **Feedback** → edit, re-verify, stop again. A file moves to another commit or a commit splits → update the §7 table and todos first, say so.
6. **"commit"** → for each commit of the phase, in order:
   - stage only its `Contains` paths (`git add {paths}`); a file shared by two commits → stage its part with `git apply --cached {patch}` (no interactive `add -p`)
   - verify it alone: `git stash push --keep-index --include-untracked` → typecheck + tests → `git stash pop`. Fails → stop and report; never commit a broken one
   - `git commit` with the planned message (plus the repo's attribution rules); row → `committed {short sha}`, todo → `completed`
7. **Phase done** — working tree clean → `MR n/N ready: {branch}, {k} commits, {f} files`. Fill this sha into later phases' **Cherry-picks**, then step 1 for the next phase in the same turn. Last phase → list every branch; nothing pushed.

End every stop with `Plan saved at: /abs/path/to/file.plan.md`.

**Never:** commit without "commit" · start the next phase before this one's commits exist · merge two planned commits into one or mix them · amend or rebase a committed commit without asking · push or open an MR unasked.
