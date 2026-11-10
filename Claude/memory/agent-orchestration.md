# Agent orchestration

How to split work between the main session and sub-agents.

## Main session or sub-agent

| Do it in the main session | Use a sub-agent |
|---|---|
| A lookup, a one-file edit, a few PR/MR replies, an answer | Changes across many files or packages |
| Anything under about 5 tool calls | Long jobs: rebase/fold/push a stack, test runs, CI log investigation |
| Work that needs quick back-and-forth with the user | Several independent jobs in parallel |
| | Anything that would flood the main context with logs |

Say in one line which you chose when it isn't obvious. Keep the main session free so the
user can send new tasks while agents run.

*Why: a sub-agent starts cold (re-reads the brief and the code, often sets up a worktree and
installs packages), and hands back only a summary. That costs more than it saves on small
jobs, but it keeps parallel and long work out of the user's way.*

## How many at once

- **At most 3 sub-agents at a time**, in waves: start the next one as one finishes.
- **At most one of them runs page/UI test suites at a time.** The others run typecheck and
  unit tests, then queue their page tests.
  *Why: parallel test runs plus dev servers pushed the load average to 15–18, and tests
  stalled for 15 minutes each.*
- One agent per independent unit (e.g. one per MR). Never two agents on the same branch.

## Which model

| Model | Jobs |
|---|---|
| Strongest (e.g. Opus) | Building code: features, fixes, specs, conflict resolution that changes logic. Planning: plans, design decisions, turning review comments into a decision. |
| Cheaper (e.g. Sonnet) | Rebase/fold/push with no logic conflicts, PR/MR replies and resolves, MR descriptions, reading CI logs, searches and lookups, starting servers. |

If a cheap-model agent hits a conflict or failure that needs a code decision, it stops and
reports, and a strong-model agent does the fix.

*Why: sub-agents inheriting the strongest model were 95% of usage.*

## Briefing an agent

- Give it the goal, what is already ruled out, the files and docs to read, and an explicit
  scope. The brief is its only context.
- State the safety rules in every brief: never commit/push unless told, never bypass hooks,
  never read secrets files, no destructive DB scripts, no code comments.
- Ask for a structured return (commits, decisions per item, checks run and results,
  anything left open) and for the result to be written to a file next to the plan.

## Checks

- **Scoped tests only**: run the test files that changed plus the existing tests of each
  changed source file. No whole-module or full-suite runs (the user and CI run those).
- **Run checks once**, when the agent's work is done, not per commit and not after a rebase.
- Format with the project's auto-fixer instead of hand fixes.
- A test that stalls under load is rerun alone before it is called a failure.
- Check a test run by its exit code: unhandled errors fail a run even when every test
  passes.

## Workspace

- Each agent works in its own git worktree; never in the user's checkout, unless told.
- If the lockfile matches the main checkout, reuse its installed dependencies instead of a
  fresh install; build shared libraries only when they changed.
- **Keep a stack's working notes** (review triage, user decisions, fold log, MR→branch map)
  **next to its plan in the plans folder**, not in a temporary scratchpad.
  *Why: a session restart wiped the scratchpad and the triage had to be rebuilt from
  transcripts.*
- Tag the old tip before any history rewrite, so it can be rolled back.
