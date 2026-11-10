# MR stacking

How a large feature turns into merge requests (MRs / PRs).

## Shape of the stack

- **One chain per feature group**: `{default} ← B1 ← B2 ← … ← F1 ← F2 ← next feature …`.
  Backend and frontend branches sit in the same chain; never two stacks off the default
  branch (`{default} ← BE…`, `{default} ← FE…`) unless the user asks. The top branch is
  the test branch.
  *Why: one chain means one place to test the whole feature and one merge order.*
- **4 MRs + 1 local test branch per feature, always all of them** (even when the backend
  is already merged; 3 and 4 never fold into one):

  | Branch | Contains |
  |---|---|
  | 1 · Backend core | module setup + domain (entities, value objects, rules, errors) + application (use cases and the ports they call) |
  | 2 · Backend adapters | inbound (controllers, DTOs, access policy) + outbound (repositories, query services, migration) + wiring + integration tests |
  | 3 · Frontend, not on the API yet | pages, routing, components; the page shows its default state (what it shows when the API fails or returns nothing); page test for that state |
  | 4 · Integrate frontend with backend | API client, hooks, query keys; the page reads from the hooks; page tests with a faked backend for loaded / empty / error |
  | 5 · Test branch | local only, never pushed: merges the whole chain, plus sample data / mocks / debug for trying it |

  Commits inside each MR keep layer order (domain first, repository + migration last).
  Every branch tip must build and pass its tests on its own.
  *Why: one MR per layer turned a 2-tab feature into 15 MRs. Every review fix crossed
  several MRs, and every fold rewrote the whole stack.*
- The next feature of the same page continues the chain on top of the last branch, named
  `{prefix}_{feature}-{n}-{focus}` with `n` counting on.
- Each MR description says which MR it depends on and the merge order.

## Frontend split (branches 3 and 4)

The split only pays off if 4 is a small change on top of 3:

- **Real types in 3.** Take response shapes from the shared contract or the types branch 2
  defines, never invented ones. *Why: invented shapes turn 4 into a component rewrite.*
- **Components take data as props.** In 3 the page passes the default/empty data; in 4 the
  page takes it from the hooks. The components do not change in 4.
- **No fake data in 3's code.** Sample rows for trying the UI go in the test branch (5).
- **The default state is real work.** The page needs it anyway when the API errors or
  returns nothing; 4's page tests check it against a faked backend.
- **3 merged alone shows an always-empty page** on the integration branch until 4 lands.
  Fine there; never let 3 alone reach a release branch.
- **A review fix in 3** → merge the parent into 4 and 5, no rebase.
- **Smell:** if 4 starts changing components and not only wiring the page to hooks, 3 was
  split in the wrong place.

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
