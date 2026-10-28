---
name: commit-checkpoint
description: Commit pattern — one commit per checkpoint state (folder structure → domain → application → ports/adapters → … → migration), every commit builds and passes tests when checked out alone, and commits group into stacked branches by review focus. Use when committing multi-step work, splitting work into commits or branches, planning a commit/branch stack, or building a new module step by step.
---

# Commit checkpoint

## Uses

None — root skill.

> **One commit = one checkpoint state. Every commit checks out green. One branch = one review focus.**

## Checkpoint order

New module (port-adapter):

| # | Checkpoint | Ships with |
|---|---|---|
| 1 | Init folder structure — module folders, module file, registration | — |
| 2 | Domain — value objects, entities | unit tests |
| 3 | Application — use cases (+ the port interfaces they call) | e2e tests on fake ports |
| 4 | Ports + adapters | adapter tests |
| 5 | Service (if any) | unit tests |
| 6 | Validator (if any) | unit tests |
| 7 | Handler | tests |
| 8 | Presentation — controller / route / DTO | e2e tests |
| 9 | Infra — DI wiring, config, module registration | — |
| 10 | Persistence entity (ORM) | mapping tests |
| 11 | Migration | — |

Other work, same idea (skip what doesn't apply):

| Work | Order |
|---|---|
| Change to an existing module | domain → application → ports / adapters → presentation → persistence → migration |
| Frontend | types / API client → state / hooks → components → page / route wiring |
| Bug fix | failing test + fix in one commit |

## Commit rules

| Rule | Why |
|---|---|
| `git checkout {sha}` → typecheck, lint, build, tests pass. | Anyone can pick any state without errors. |
| A checkpoint needs a later piece to compile → pull only that piece forward (e.g. the port interface with its use case). | Order bends, builds never break. |
| New code ships with its tests — no "add tests" commit. | Each commit proves itself. |
| Code may be unused until a later commit, never broken. | Unused builds; broken doesn't. |
| Signature / rename → every caller + their tests in the same commit. | No broken call site. |
| Big checkpoint → split by part (per entity, per use case), same layer only. | Each commit stays one state. |
| Message in the repo's `git log` style, naming the checkpoint. | `git log` reads as the build story. |

## Branch stack

Commits group into stacked branches: `{default} ← B1 ← B2 ← B3 …`, each branch off the one before, one MR each targeting its parent.

| Rule | Why |
|---|---|
| One branch = one review focus. New module: **structure** (1) · **business rules** (2) · **use cases** (3) · **wiring / API** (4–9) · **persistence** (10–11). | The reviewer checks one kind of thing per MR. |
| Target ≤ 50 files per branch; split a focus over two branches if bigger. A single checkpoint that must exceed it may. | Readable in one sitting. |
| Small foci (< 5 files) merge into the next branch. | No trivial MRs. |
| Branch name = repo convention + `-{n}-{focus}`. | The stack sorts and reads in order. |
| **Needs** = the earlier branches whose code this one compiles against — not just the one before it. Keep it minimal: a contract from the plan (types, API shape) can be written in the branch itself. | Branches with no unbuilt Needs build in parallel and restack onto their parent after. |

## Build order

Derived from **Needs** across every stack (BE, FE). A wave = all branches whose Needs are in earlier waves.

```markdown
**Build order**
| Wave | In parallel | Waits for | Restack after |
|---|---|---|---|
| 1 | B1 ∥ F1 | — | — |
| 2 | B2 ∥ F2 ∥ B4 | B2 ← B1 · F2 ← F1 · B4 ← B1 | B4 onto B3 |
| 3 | B3 | B2 | — |
```

`Restack after` = branches started below their parent, rebased onto it once it's built.
| Fix in a lower branch → fixup its owning commit, restack: `git rebase -i --autosquash --update-refs {default}` from the top branch. | Every branch above follows. |
