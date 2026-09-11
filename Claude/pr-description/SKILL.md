---
name: pr-description
description: Write a merge/pull request description from a branch's actual diff, following the repo's own MR/PR template. Use when the user asks for a PR description, MR description, PR summary, "write up this branch", or a description to paste into GitLab/GitHub. Project-agnostic — discovers the template and output path from the repo.
---

# PR description

One governing rule:

> **Every bullet is a claim a reviewer can check, plus the one mechanism they could not infer
> from the diff. Nothing else.**

A description is evidence, not marketing. Length is not thoroughness — an unread description
protects nobody.

## Workflow

1. **Read the branch.** `git log --oneline <base>..HEAD`, `git diff --stat <base>..HEAD`, then
   the diffs that matter. **Never describe a change you have not read.** Commit messages are a
   table of contents, not evidence — they lie about scope more often than they mislead about intent.
2. **Find the template**, in order — first hit wins:
   `.gitlab/merge_request_templates/*.md` → `.github/PULL_REQUEST_TEMPLATE.md` (or
   `.github/PULL_REQUEST_TEMPLATE/`) → `CONTRIBUTING.md` → none, use *Default shape* below.
   Reproduce its headings **verbatim** — emoji, `====` bars, checkbox order, HTML comments.
   Fill the template; never redesign it.
3. **Find the output convention.** Glob for existing `pr-*.md` / `mr-*.md` under `.claude/plans/`,
   `docs/`, or the repo root, and match the closest filename pattern. No precedent → print to chat
   rather than inventing a location.
4. **Group by package or layer** when the PR spans more than one (`**Frontend**` / `**Backend**` /
   `**Migration**`). One package → one flat list.
5. **Write the bullets** to the rule below.
6. **Gate the numbers** on evidence you actually collected.
7. **Add what reviewers ask about**: what you rejected, what is still undone, what must not merge.

## Bullet rule

**Bold lead — one sentence of mechanism.** Two wrapped lines, maximum.

- Lead with the **outcome and its delta** when there is one (`**Killed two N+1 loops (−30 calls).**`),
  otherwise the **subject**: file, hook, component, endpoint.
- The sentence says *why the change was necessary* — the mechanism hiding behind the diff. Not a
  restatement of what the code now looks like.
- Cut on sight: background the heading already gave, "we decided to", "in order to", and any second
  sentence that only elaborates the first.

```
✅ **`useApplyRegionEducationZoneDefault`** — the region default landed in the URL after the list
   query already fired unscoped; scoped and unscoped are different query keys, so the list now
   gates on `isPending`.

❌ **`useApplyRegionEducationZoneDefault`** — the region-scoping default was back-written to the
   URL by an effect inside a filter component, *after* the list query had already fired unscoped.
   Scoped and unscoped params are different query keys, so no cache can dedupe them. The hook now
   owns that decision and reports `isPending`; the list query gates on it and the unscoped request
   is never issued.
```

Same information. Half the words. The ❌ version spends three clauses restating the ✅ version's
first clause.

## Honesty rules — hard

These are failure modes, not style preferences.

| Rule | Why |
|---|---|
| Never write a number you did not measure. Unmeasured rows get `_(pending)_` **and** the command that produces them. | A table reads as evidence; a plausible guess inside one is a lie with formatting. |
| Leave a checklist item unticked when it is not done, and name what remains. | Ticking "tested manually" on someone else's behalf hides the risk instead of transferring it. |
| Add **"Investigated, deliberately not changed"** whenever you rejected an obvious fix. | Reviewers ask about exactly those; silence reads as oversight. |
| Flag anything in the tree that must not merge — commented-out code, debug flags, scoped-down configs. | Invisible in a description that does not mention it. |
| Label projections as expected; reserve "Measured" for measurements. | `29 → ~15 (expected)` is honest. `29 → 15` under a Measured heading is not. |

## Default shape

Only when the repo has no template:

```markdown
## What and why
{One sentence: the problem, and the state after this PR.}

## Changes
{Grouped bullets, per the bullet rule.}

## Verification
{Commands run and their result. Measured numbers only.}

## Notes for the reviewer
{Rejected alternatives, what is still undone, anything that must not merge.}
```

## Anti-patterns

| Smell | Fix |
|---|---|
| Bullet restates its own bold lead | Delete the restatement; keep the mechanism |
| "Refactored X for better maintainability" | Name what was wrong with X before |
| Measured table filled from expectation | `_(pending)_` + the command |
| Every checklist item ticked | Tick only what you did; name the rest |
| Bullet per commit | Bullet per *change* — squash the fixup commits into one claim |
| File list with no mechanism | The diff already lists files; say why they changed |
| Rejected fix left unmentioned | "Investigated, deliberately not changed" |
