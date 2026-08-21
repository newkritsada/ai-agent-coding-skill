---
name: function-flow
description: Function-based clean code style — decompose code so the top-level function reads like a flowchart of named steps. Use whenever writing or refactoring any function longer than ~30 lines, a script, a seed/backfill job, a handler, or a service method — especially when the user says "clean", "readable", "refactor", "split into functions", or the code mixes fetching, deciding, and writing in one body, or a function's parameter list has grown long. Project-agnostic; applies to any language or package.
---

# Function Flow — code that reads like a flowchart

One governing rule:

> **A human should understand what a function does by reading only the names of the
> functions it calls — top to bottom, like a flowchart. Details live one level down.**

## The shape

The top-level function is pure narrative — each line is a named step, no inline logic:

```ts
async function run() {
  const config = loadConfig()                      // throws if config is invalid
  const desired = resolveDesiredState(config)      // pure: what SHOULD exist
  const current = await loadCurrentState(config)   // what DOES exist

  const plan = planChanges(desired, current)       // pure diff → explicit actions
  await applyPlan(plan)                            // the ONLY step with side effects
  reportSummary(plan)                              // counts derived from the plan
}
```

As a flowchart: **load → resolve → plan → apply → report.**
If you can't tell what the code does from this view alone, the decomposition failed.

## Rules

1. **One function, one step.** Each extracted function does exactly what its name
   says, nothing more. If the name needs "and", split it.
2. **Names are verb + outcome**, drawn from a small standard vocabulary so the flow
   is scannable: `load*` / `find*` / `fetch*` (read), `build*` / `resolve*`
   (compute desired state), `plan*` (pure diff), `apply*` / `save*` (write),
   `report*` (log/output), `validate*` / `check*` (throw early).
3. **Separate deciding from doing.** Decision logic is a *pure* function that
   returns a plan — a plain object of explicit actions:

   ```ts
   interface ItemChange {
     action: 'create' | 'update' | 'unchanged'
     // ...ids / payloads the apply step needs
   }
   ```

   Exactly **one** `apply` function performs side effects, by consuming the plan.
   This makes the logic unit-testable without mocks, and a dry-run mode a one-line
   change (print the plan, skip apply).
4. **Data flows through parameters and return values** — not shared fields or
   counters mutated mid-loop. Derive summaries/stats *from the plan* at the end
   instead of incrementing counters while working.
5. **Keep the argument list short.** Every added argument multiplies the cases a
   test must cover and the orderings a caller can get wrong.

   | Args | Verdict |
   |---|---|
   | 0 | Ideal — nothing to get wrong |
   | 1 | Ideal — one input, one outcome |
   | 2 | Acceptable — change a value, or combine two |
   | 3 | Justify it; prefer 2 |
   | 4+ | Refactor: bundle a real concept, or split the function |

   - **Zero must be honest.** 0 is ideal only when the function truly needs no
     input (`run()`, `loadConfig()`). Never reach 0 by hoisting an argument into a
     class field or module global — that hides the dependency instead of removing
     it, and rule 4 outranks the count. An honest 2 beats a dishonest 0.
   - **An object counts as 1 only if its type names a concept** — `ItemChange`,
     `DateRange`, something that travels whole and could be returned by a `plan*`
     step. `seed(opts: SeedOptions)` holding `{ db, logger, dryRun, chunk, force }`
     is still five arguments wearing a coat; split the function instead.
   - **Not counted:** constructor / DI parameters (wiring declared once, no
     call-site ordering risk) and framework-fixed signatures (exception filters,
     middleware, `map` callbacks) — count only the arguments you added.
   - Two same-typed arguments are fine when the verb states the order —
     `transfer(from, to)`, `copyFile(source, dest)` read better than any wrapper.
     When the name gives no order cue (`grant(userId, orgId)`), fix it by renaming
     or using distinct types — not by wrapping the pair in an object.
6. **A comment naming a section is a function waiting to be extracted.** Instead of
   `// find items missing from the source`, write `findMissingItems()`. Keep only
   comments stating what code cannot say (constraints, invariants, why an order
   matters).
7. **Group functions in reading order** under section banners matching the flow:

   ```ts
   // ---------- load ----------
   // ---------- resolve desired state ----------
   // ---------- plan ----------
   // ---------- apply ----------
   // ---------- report ----------
   ```
8. **Branching lives inside named functions, not the orchestrator.** A per-item
   decision becomes `planItemChange(desired, existing): ItemChange` built from guard
   clauses and early returns — the caller just aggregates results:

   ```ts
   function planItemChange(desired: Item, existing?: Item): ItemChange {
     if (!existing) return { action: 'create', item: desired }
     if (isSame(existing, desired)) return { action: 'unchanged' }
     return { action: 'update', id: existing.id, item: desired }
   }
   ```
9. **Validate up front, fail fast.** Preconditions (config sanity, required rows,
   conflicting inputs) are checked in `load*`/`build*` steps that throw with a
   message saying what to fix — never deep inside the work loop.
10. **Tiny expression helpers are worth extracting too** when repeated:
   `formatLabel(item)` beats three copies of the same template literal.
11. **Error handling and cleanup live at the top level only** (transaction
    begin/commit/rollback, connection release, `finally`). Inner steps throw; they
    don't handle.

## Refactor procedure (existing code)

1. Read the function; write its steps as a comment list — that list *is* your new
   top-level function.
2. Extract each step into a function named after the comment; pass data explicitly.
3. Pull all side-effecting writes into one `apply*` function fed by a `plan` object;
   make everything upstream of it pure.
4. Replace mid-loop counters with values derived from the plan in `report*`.
5. Re-read only the top-level function: if any line needs a comment to be
   understood, rename the function it calls.
6. Verify with the project's own checks (lint, typecheck, tests); behavior must be
   unchanged unless the user asked otherwise.

## Anti-patterns

| Smell | Fix |
|---|---|
| 100-line function with `// section` comments | Each comment becomes a named function |
| Fetch + decide + write interleaved in one loop | Split into resolve → plan (pure) → apply |
| `total += 1` scattered through the body | Count from the plan in `report*` |
| Orchestrator full of `if/else` | Push branches into a `plan*` function returning explicit actions |
| Boolean/flag parameters steering behavior | Two well-named functions, or an explicit action type |
| Signature grown to 4+ parameters | Bundle the ones that form a real concept; otherwise the function is doing more than one step — split it |
| Helper doing "its thing + logging + saving" | One responsibility; move logging to `report*`, writes to `apply*` |
| Deciding and writing in the same function | Return the decision; let `apply*` act on it |
| Over-extraction: one-line functions called once with no name value | Inline it — extraction must buy readability, not indirection |

## In-repo reference

A full worked example (transactional upsert seed with load/resolve/plan/apply/report,
chunked writes, conflict reporting):
`packages/school-core-api/src/database/scripts/seed-training-map-teacher-classroom.ts`
