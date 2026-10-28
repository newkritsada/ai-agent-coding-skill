# Plan → build flow

Feature from idea to stacked MRs: `/plan-feature` plans it, `/build-stack` builds it.
Example below: a **quiz attempt** module (BE + FE).

## Skill map

| Skill | Started by | Role | Uses |
|---|---|---|---|
| `plan-feature` | you | plan in 3 gated stages | `plan-diagram-archify`, `plan-pattern`, `clean-architecture` (Pick), `commit-checkpoint` |
| `build-stack` | you | build the stack (parallel where `Needs` allows), review, push | `commit-checkpoint`, `clean-architecture` (Pick), `pr-description` |
| `build-plan` | you | build any plan's §7, no stack | `plan-pattern`, `clean-architecture` |
| `plan-diagram-archify` | plan-feature / you | plan + archify diagram Artifact | `plan-pattern`, `archify` |
| `plan-pattern` | every plan | plan file shape, grilling, `Plan saved at` | `grilling` |
| `clean-architecture` | build skills / Claude | Pick: structure → `port-adapter-architecture` + `clean-function`; one layer → `clean-function` | both roots |
| `commit-checkpoint` | Claude, on its own | checkpoint order, commit rules, branch stack, `Needs` | — |

Roots (use nothing): `grilling`, `clean-function`, `port-adapter-architecture`, `commit-checkpoint`.

## 1. Plan — `/plan-feature`

```
/plan-feature add quiz attempt — student starts a quiz, answers, submits, gets a score
```

| Stage | Claude does | You say |
|---|---|---|
| BE | plan mode → grilling → `quiz_attempt-be.diagram.md` → exit plan mode → render diagram Artifact | feedback … then `approve` |
| | Checkpoint + **compact suggestion** → enters plan mode | (`/compact …`) then `next` |
| FE | same, reads the BE plan → `quiz_attempt-fe.diagram.md` | feedback … then `approve` |
| | Checkpoint + **compact suggestion** → enters plan mode | (`/compact …`) then `next` |
| Summary | `quiz_attempt.summary.md` — BE + FE + integration + §7 branch stack + **Build order** (what runs in parallel, what waits) | feedback … then `approve` |
| | Checkpoint + **compact suggestion** → enters plan mode, waits | `/build-stack quiz_attempt.summary.md` |

Resume any time in a new session: `/plan-feature quiz` or `next`.

## 2. Build — `/build-stack`

```
main ← B1 quiz-attempt-1-structure ← B2 …-2-domain ← B3 …-3-usecase ← B4 …-4-api ← B5 …-5-persistence
```

- One agent per branch. Every branch whose `Needs` are built starts at once — BE and FE, and branches in one stack that don't compile against each other. Started below its parent → rebased onto it once the parent is built.

```
B1 structure · B2 domain (Needs B1) · B3 use case (Needs B2) · F1 types + API client · F2 components (Needs F1)
wave 1: B1 ∥ F1    wave 2: B2 ∥ F2    wave 3: B3
```

- Each commit = one checkpoint, proven green alone (`git rebase --exec`). Nothing pushed.
- Ends with the review table + **compact suggestion**.

## 3. Review → push

| You say | Claude does |
|---|---|
| `B2: rename Score to AttemptScore` | fixup the owning commit → restack B3–B5 → re-check → review table |
| `push B1` | `git push` + `glab mr create` B1 → `main` |
| `push B2` | push + MR B2 → B1 (parent must be pushed first) |
| `B1 merged` | rebase the rest onto `main`, check the next MR's target |

## Compact wording

Claude prints these filled in; copy, paste, run. Then say `next` (plan) or your next review / push (build).

```
/compact Keep for plan-feature: topic quiz; next stage FE; plans /…/quiz_attempt-be.diagram.md; artifacts https://claude.ai/…. Drop diagram JSON, grilling and review chatter.
```

```
/compact Keep for build-stack: plan /…/quiz_attempt.summary.md; stack B1 quiz-attempt-1-structure pushed, B2 …-2-domain built, …; next review B2. Drop agent output and diffs.
```

When: after each `approve` (plan) · after the build and after each `push` (build) · any time the context feels long.

## Without plan-feature

`/build-stack any-plan.md` — no stack in §7 → Claude proposes one per `commit-checkpoint`, waits for `ok`, then builds.
