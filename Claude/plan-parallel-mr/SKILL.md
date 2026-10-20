---
name: plan-parallel-mr
description: Plan a large feature as phases — one independent MR per phase (<30 files, cap 50), each with self-contained commits, one agent per phase — then build all phases in parallel agents on isolated worktrees (shared commits first), hand over the branches in review order, and merge every phase branch into a local final branch to test the whole feature. Manual launcher — invoke with /plan-parallel-mr.
disable-model-invocation: true
---

# Plan parallel MR

> **Every MR merges alone. Every commit builds alone. Every phase builds at once.**

## Modes

| Invoked with | Mode |
|---|---|
| a feature / requirement | **Plan** |
| a plan path or file name, "build", "continue", "commit" | **Build** |

## Plan

1. Follow `../plan-pattern/SKILL.md` fully. Enhance: only §7 and the todos, as below.
2. Estimate changed files from §3–§5. Total ≤ 30 → one phase. More → split by **Phase rules**.
3. Grill on the split too: phase boundaries, shared commits, each cherry-pick → §8 rows.
4. Write §7 per **§7 template**. Todos = one per commit, `id: p1-c1`, `content:` the commit message.
5. **Chains** = number of **Cherry-picks** entries across all phases. ≥ 3 → recommend **Commit-all**; < 3 → **Gated**.

## Phase rules

| Rule | Why |
|---|---|
| 1 phase = 1 MR = 1 branch off the default branch (the MR target), named per repo convention. 1 phase = 1 agent. | Each MR reviews and merges on its own; each agent owns one branch. |
| **Never branch a phase off another phase.** | A chain: one review fix rebases every MR after it. |
| Target < 30 files changed, cap 50. Over → split. | A reviewer reads it in one sitting. |
| Order: foundation (schema, entities, ports, shared types) → features → wiring / cleanup. | Later phases need only early, stable commits. |
| Phase needs another phase's commit → cherry-pick it; list it under **Cherry-picks**. | Dependency is explicit and one commit wide. |
| Shared commits (picked by another phase) go first in their phase, small, stable — and pick nothing themselves; one needs a pick → put both in one foundation phase. | Wave 0 builds them with no waiting. |
| > 2 picks in one phase → too coupled: merge those phases or move the picked commits into a foundation phase. | Too many picks is a chain in disguise. |
| A picked commit changes → re-pick it in every phase that lists it. | Phases stay in sync. |
| The source MR merges → rebase the dependent phase onto the default branch. | Git drops the identical picked commit. |

## Commit rules

| Rule | Why |
|---|---|
| Builds, lints, tests pass on its own — on its branch and cherry-picked alone onto the default branch (plus its listed picks). | Anyone can pick it. |
| Signature / rename change → every caller and their tests in the same commit. | No broken call site. |
| Schema change → migration + entity + mapping together. | Code and database agree. |
| New code ships with its tests. | Each commit proves itself. |
| Code may be unused until a later commit, never broken until one. | Unused builds; broken doesn't. |
| One concern per commit, ~≤ 10 files. Message in the repo's `git log` style. | Reviewable commit by commit. |
| Every file in exactly one commit of its phase where possible. | Committing stays mechanical. |

## §7 template

```markdown
## 7. Steps

**Chains:** {n} cherry-picks → recommended **{Commit-all | Gated}** · **Final branch:** `{final}` (local only)

### Phase 1 — {title} · MR 1/{N} · Agent A1
- **Branch:** `{repo convention}` from `{default branch}`
- **Cherry-picks:** None
- **Files:** ~{n} (target < 30, cap 50)

| # | Commit message | Contains | Files | Wave | Status |
|---|---|---|---|---|---|
| P1-C1 | {message} | `{path}`, `{spec path}` | {n} | 0 | pending |
| P1-C2 | {message} | `{path}`, `{spec path}` | {n} | 1 | pending |

### Phase 2 — {title} · MR 2/{N} · Agent A2
- **Branch:** `{repo convention}` from `{default branch}`
- **Cherry-picks:** P1-C1 `{sha once committed}` — {why}
- **Files:** ~{n}

| # | Commit message | Contains | Files | Wave | Status |
|---|---|---|---|---|---|
| P2-C1 | {message} | `{path}`, `{spec path}` | {n} | 1 | pending |
```

`Contains` = staging list — real paths or globs. Wave 0 = shared commits, else 1. Status: `pending` → `review` → `committed {sha}`.

## Build

Get the plan per `../plan-pattern/SKILL.md` **Using a plan**; pick the code-style skill per `../plan-clean-structure/SKILL.md` — read it, don't run it. Ask the mode once, recommendation first.

### Waves

| Wave | Who | Builds |
|---|---|---|
| 0 | phases with Wave-0 commits | only those commits |
| 1 | every phase, in parallel | cherry-pick listed SHAs, then the rest; owners continue on the same branch |

| Mode | After wave 0 | After wave 1 |
|---|---|---|
| Gated | stop → **Review order** → "commit" → commit them | stop, uncommitted → **Review order** → "commit" → commit all → **Final branch** |
| Commit-all | commit, continue | commit → **Final branch** → **Review order** |

No Wave-0 commits → wave 1 only.

### Agents

- One `Agent` per phase, `isolation: "worktree"`; a wave's agents in one message; max 5 at once, queue the rest.
- Prompt: plan path, phase id, wave, mode, picks + SHAs, code-style skill path, this file's path. The agent: `git fetch` → `git switch -c {branch} origin/{default}` (wave 0) or stays on it (wave 1) → `git cherry-pick {sha}` per pick (conflict → stop, report) → builds its wave's commits in table order → runs the repo's typecheck / lint / build + tests for touched code, fixes failures → **Commit a phase** if the mode says so now.
- Agent never: edits the plan, pushes, touches another branch. Returns: branch, worktree path, per commit `{sha}` or `uncommitted`, checks + result.
- Main session owns the plan: after each wave update §7 rows, todos (`in_progress` / `completed`), later phases' **Cherry-picks** SHAs.
- Branch fully committed → `git worktree remove` it, keep the branch. Uncommitted → keep the worktree; on "commit" `SendMessage` that agent.

### Commit a phase

Per commit, in table order:
- stage only its `Contains` (`git add {paths}`); a file shared by two commits → `git apply --cached {patch}` (no `add -p`)
- verify alone: `git stash push --keep-index --include-untracked` → typecheck + tests → `git stash pop`. Fails → stop, report; never commit a broken one
- `git commit` with the planned message (+ repo attribution); row → `committed {short sha}`

### Review order

Every stop lists branches to review — Wave-0 owners first, then phase number, final branch last. Mark ones changed since the last stop.

| # | Branch | Phase | Commits | Review with |
|---|---|---|---|---|
| 1 | `{branch}` | P1 — {title} | P1-C1…C3 | `git switch {branch}` · `git diff origin/{default}...{branch}` |
| 2 | `{branch}` (uncommitted) | P2 — {title} | — | `cd {worktree}` · `git diff` |
| 3 | `{final}` (local) | all | — | `git switch {final}`, run the app |

### Review fixes

- Uncommitted (Gated) → edit in that phase's worktree, re-verify, stop again. A file moves commit / a commit splits → update §7 + todos first, say so.
- Committed (Commit-all) → per comment, the commit that owns it; one worktree agent per affected branch, parallel:
  1. edit → `git commit --fixup {sha}` → `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/{default}` → re-verify (allowed: user asked, branch unpushed)
  2. commit picked elsewhere → re-pick in every phase listing it, re-verify
  3. update §7 SHAs → rebuild **Final branch** → **Review order**

### Final branch

Only when every phase is fully committed.

1. `git worktree add {tmp} -b {final} origin/{default}`; `{final}` = repo branch convention + `{group}-final`. Exists → delete, recreate.
2. `git merge --no-ff {branch}` per phase, phase order. Conflict → stop, list files, ask.
3. Repo's full typecheck / lint / build / all tests. Fail → fix in the owning commit (**Review fixes**), rebuild.
4. Each §1 requirement → `| Requirement | Verified by | Result |`.
5. `git worktree remove {tmp}`, keep the branch.

Done → list every phase branch + `{final}`; end per plan-pattern **Using a plan**.

**Never:** commit in Gated without "commit" · two agents on one branch · an agent edits the plan · merge two planned commits or mix them · rebase a commit beyond **Review fixes** without asking · Final branch with anything uncommitted · push any branch or open an MR unasked.
