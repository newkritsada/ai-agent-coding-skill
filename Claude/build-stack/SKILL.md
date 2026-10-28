---
name: build-stack
description: Build a plan's §7 stack as stacked branches ({default} ← B1 ← B2 …) — one agent per branch, branches that don't need each other's code built in parallel and restacked after, checkpoint commits per commit-checkpoint, every commit verified alone — then the user reviews each branch, and on "push" it pushes and opens a GitLab MR targeting the parent branch. Manual launcher — invoke with /build-stack.
disable-model-invocation: true
---

# Build stack

## Uses

Load a skill by name: read `~/.claude/skills/<name>/SKILL.md`.

1. `/commit-checkpoint` — commits, branches, Needs
2. `/clean-architecture` — **Pick** only — which code-style skills agents load
3. `/pr-description` — MR text, if present

- **Plan** — the path the user gave (bare name → the plans folder; usually `*.summary.md` from plan-feature) → else this session's last `Plan saved at:` → else ask. Don't load plan-pattern — §7 is all this skill needs.
- **Commits, branches** — `/commit-checkpoint`.
- **Code style** — `/clean-architecture` **Pick** only, per branch. Agents get the picked skill paths, not clean-architecture.

Before building, print §7's **Build order** (per `/commit-checkpoint`) — what runs in parallel, what waits, what restacks. No stack, no `Needs` or no Build order → write them into §7, show them, wait for "ok".

## Build

Commit first, review after. Parallel wherever **Needs** allows — wait only for a branch whose code you compile against.

1. **Ready** = every branch in its `Needs` is built. Start all ready branches together — every stack, one message, ≤ 5 agents, queue the rest. Each agent returns → recheck what's ready.
2. **Start point** = the newest built branch on its parent chain (none → `origin/{default}`, after `git fetch`). Parent not built yet → the branch restacks later.
3. Agent prompt: plan path, branch id, start point, parent, repo path, picked code-style skill paths, commit-checkpoint path, the repo's check commands. The agent:
   - `git -C {repo} worktree add ../{repo}-wt/{branch} -b {branch} {start}`
   - per commit in table order: build it → checks pass → `git add {Contains}` → `git commit` (planned message + repo attribution)
   - prove each commit alone: `git rebase --exec "{checks}" {start}`; fix the owning commit on failure
   - keeps the worktree; never edits the plan, pushes, or touches another branch
   - returns: branch, start point, per commit `{sha} {message}`, files changed, checks + result
4. **Restack** — a branch's parent is built and it started below the parent → `SendMessage` its agent: `git rebase --onto {parent} {start} {branch}` → `git rebase --exec "{checks}" {parent}`. Conflict → resolve keeping both intents; can't → stop, report the files.
5. Branch on its real parent and green → `git worktree remove`, keep the branch.
6. Main session after each agent: §7 commit rows → `built {sha}`, branch row → `built` / `restacked`, todos → `completed`.
7. All on their parents → **Review** + **Compact**.

```
Example — BE B1 structure, B2 domain (Needs B1), B3 use case (Needs B2); FE F1 types + API client, F2 components (Needs F1)
wave 1: B1 ∥ F1          wave 2: B2 ∥ F2          wave 3: B3
```

## Compact

Suggest after the build and after each "push". Print it filled in, ready to paste — the user runs it; you can't:

```
Suggest: /compact Keep for build-stack: plan {abs path}; stack {B1 {branch} {status}, B2 …}; next {review B{n} | push B{n}}. Drop agent output and diffs.
```

After a compact, the next message from the user → read `~/.claude/skills/build-stack/SKILL.md` and the plan's §7 first.

## Review

```
| # | Branch | Parent | Focus | Commits | Files | Status | Review with |
| B1 | {branch} | {default} | structure | 2 | 14 | built | git log --oneline {parent}..{branch} · git diff {parent}...{branch} |
```

| User says | Do |
|---|---|
| comment on branch Bn | fix in the owning commit: worktree on the top branch → edit → `git commit --fixup {sha}` → `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash --update-refs {base}` → `git rebase --exec "{checks}" {base}` → update SHAs → **Review** |
| "push Bn" | parent pushed (or the default) → `git push -u origin {branch}` → `glab mr create --source-branch {branch} --target-branch {parent} --title {…} --description {…}` (description per `/pr-description` if present) → status `pushed {MR URL}` |
| Bn merged | `git rebase --update-refs --onto origin/{default} {Bn} {top}`; GitLab retargets the next MR when the merged branch is deleted — check, else `glab mr update --target-branch` |

End every stop with the **Review** table and `Plan saved at: /abs/path`.

**Never:** push or open an MR without "push" · push a branch before its parent · two agents on one branch · an agent edits the plan · a commit that fails checks alone · start a branch before its `Needs` are built · rebase a pushed branch without asking.
