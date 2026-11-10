# MR stacking

How a large feature turns into merge requests (MRs / PRs).

## Shape of the stack

- **One chain per feature group**: `{default} ← B1 ← B2 ← … ← F1 ← F2 ← next feature …`.
  Backend and frontend branches sit in the same chain; never two stacks off the default
  branch (`{default} ← BE…`, `{default} ← FE…`) unless the user asks. The top branch is
  the test branch.
  *Why: one chain means one place to test the whole feature and one merge order.*
- **At most 4 MRs per feature**:

  | MR | Contains |
  |---|---|
  | 1 · Backend core | module setup + domain (entities, value objects, rules, errors) + application (use cases and the ports they call) |
  | 2 · Backend adapters | inbound (controllers, DTOs, access policy) + outbound (repositories, query services, migration) + wiring + integration tests |
  | 3 · Frontend data + components | API client, hooks, schemas, presentational components |
  | 4 · Frontend page | pages, routing, page-level tests |

  Commits inside each MR keep layer order (domain first, repository + migration last).
  Every branch tip must build and pass its tests on its own.
  *Why: one MR per layer turned a 2-tab feature into 15 MRs. Every review fix crossed
  several MRs, and every fold rewrote the whole stack.*
- The next feature of the same page continues the chain on top of the last branch, named
  `{prefix}_{feature}-{n}-{focus}` with `n` counting on.
- Each MR description says which MR it depends on and the merge order.

## CI

- Let CI run on the **first push of every branch and after each fold**. Skip CI only for a
  push that changes nothing CI checks.
  *Why: skipping CI for many review rounds hid integration-test, policy, contract and
  security failures until late, and they all landed at once.*
- Tests that need infrastructure the local machine lacks (a real DB stack, a queue) only
  run in CI. Say so plainly in the MR.

## While the stack is in review

- **New work becomes a new MR from the default branch**, not a fold into the stack.
- **Before rebasing a pushed stack, ask whether the user will merge the current MRs
  first.** A rebase gets thrown away when they merge the old version.
- **MR conflicts: merge the target into the branch** in one merge commit. No rebase and no
  force-push on a branch under review. Resolve both sides' intent, never blindly
  `-X ours/theirs` when both changed logic.
- **Force-push only with an explicit OK**, and always `--force-with-lease=<branch>:<sha>`.
- When a lower MR merges, merge the default branch into the next one so its diff shows only
  its own commits.

## Shared components from another repo

- If a feature needs new components in a shared UI library (separate repo/package), get
  that PR **merged and released before the feature MR goes to review**. Pin the released
  version. A pre-release snapshot is for local testing only.
  *Why: a snapshot pin blocked a merge for hours once the target bumped the library and no
  published version had both sides' components.*
- Only dumb, generic components go to the shared library. Ask: "would another screen use
  this as is?"

## MR content

- Fill the repo's MR template exactly. Base it on the actual diff, not the conversation.
- Tick only what was run. Leave "tested manually" unticked until the user says so. Say
  plainly what is untested or environment-dependent.
- Reply on every review thread: agree → fix, cite the commit, resolve; disagree → give the
  reason in one or two sentences, resolve. A point that needs a product decision stays open
  and goes to the user.
