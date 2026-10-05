---
name: clean-function
description: Function-based clean code style — the orchestrating function reads like a flowchart of named steps, and every function is small, single-purpose, and has few arguments. Use whenever writing a NEW function longer than ~30 lines, a script, a seed/backfill job, or a service method. Refactor existing functions only when the user explicitly asks ("refactor", "clean this", "split into functions"). Project-agnostic; applies to any language or package.
---

# Clean Function

> **Reading only the names an orchestrator calls, top to bottom, tells you what it does.
> Details live one level down.**

## 0. Scope — new code only

- **New function** → apply this skill fully.
- **Existing function** → don't restructure it. Make the smallest change that does the
  task, in its current style. Big rewrites hide bugs and bloat the diff.
- New logic added inside an existing function may go in a **new** helper that follows
  this skill; the existing body just calls it.
- Refactor existing code (§5) **only when the user explicitly asks**. If an existing
  function would clearly benefit, suggest it in one line — don't do it.

## 1. Who orchestrates

| Situation | Orchestrator |
|---|---|
| The workflow has an entry function (service / use-case method, job, script) | That entry function |
| No such function yet | The **main function** |
| Flow is big (many phases) | Main calls a few **child orchestrators**, one per phase |

- **Transport code never orchestrates** (controllers, routes, CLI parsers, event
  listeners). It stays a few lines: validate input → call one orchestrator → return.
- Nest orchestrators **one level** by default. Deeper only when a phase is itself large.
- **Pure steps stay flat.** Don't split a pure function into children unless the piece
  is reused or names a real concept. Fewer clean functions beat many tiny ones.

```ts
async function run() {
  const config = loadConfig()                    // throws if invalid
  const desired = resolveDesiredState(config)    // pure
  const current = await loadCurrentState(config) // fixed query count
  const plan = planChanges(desired, current)     // pure diff → actions
  await applyPlan(plan)                          // only side effects
  reportSummary(plan)
}
```

**load → resolve → plan → apply → report.** If this view alone doesn't explain the code,
the decomposition failed.

## 2. Where each line goes

| The code decides… | Goes in |
|---|---|
| What order steps happen in | Orchestrator |
| That something missing is an error | Orchestrator — `load*`/`find*` return `null`/empty |
| Whether a value or state is legal | Pure `validate*` / domain function |
| What should change | Pure `plan*` returning explicit actions |
| How data is read or written | `load*` / `apply*` — IO only, no decisions |
| How a row becomes an object | Pure `map*` |
| How an error becomes a status / exit code | The edge (controller, filter, `main` catch) |

**Pure core, IO at the edges:** pure steps ← orchestrator ← IO steps.

## 3. Orchestrator rules

1. **Each line is a named step** — no inline loops, branches, or expressions.
2. **Decide, then do.** One `apply*` performs all side effects from the plan.
   (Dry-run = print the plan, skip apply.)
3. **Data flows through args and returns** — no shared fields or mid-loop counters.
   Derive stats from the plan in `report*`.
4. **Validate up front**; fail fast before any write.
5. **Owns transaction and cleanup** (`begin/commit/rollback`, `finally`). Steps throw,
   they don't catch; mapping errors to status codes stays at the edge.
6. **Query count doesn't grow with input size.** `load*` batches (`IN`, join); never a
   query per item inside a loop.
7. **Order functions in reading order** under banners: `// ---------- plan ----------`.

## 4. Every function you create

1. **One job.** If the name needs "and", split it.
2. **Reusable.** Depends only on its arguments, returns a value, no hidden state.
3. **Narrowest input.** Pass the values it needs, not a whole service, entity, or request.
4. **Name = verb + business outcome**: `load*`/`find*` read · `build*`/`resolve*` compute ·
   `plan*` diff · `apply*`/`save*` write (return nothing) · `map*` convert · `report*`
   output · `validate*` throw. Prefer `hasEarnedBadge()` over `checkRecordExists()`.
5. **Errors name the failed condition** — `BadgeNameRequiredError`, not `InvalidError`.
6. **Branch with guard clauses**, early returns, no nesting:
   ```ts
   function planItemChange(desired: Item, existing?: Item): ItemChange {
     if (!existing) return { action: 'create', item: desired }
     if (isSame(existing, desired)) return { action: 'unchanged' }
     return { action: 'update', id: existing.id, item: desired }
   }
   ```
7. **Few arguments.**

   | Args | Verdict |
   |---|---|
   | 0–1 | Ideal |
   | 2 | Fine |
   | 3 | Justify it |
   | 4+ | Split the function, or bundle a real concept |

   - Never reach 0 by hoisting an arg into a field or global — an honest 2 beats a hidden 0.
   - An object counts as 1 only if its type is a real concept (`DateRange`, `ItemChange`).
     `{ db, logger, dryRun, force }` is still four args.
   - Not counted: DI/constructor params, framework-fixed signatures.
   - Same-typed pairs are fine when the verb gives the order (`copy(from, to)`).

## 5. Refactor steps (only when the user asks)

1. Match the repo's existing style first; imitate its nearest good example.
2. List the function's steps as comments — that list is the new orchestrator.
3. Extract each step, named after its comment; pass data explicitly.
4. Move all writes into one `apply*` fed by a plan; make the rest pure.
5. Re-read only the orchestrator; rename any call that still needs a comment.
6. Run the project's lint / typecheck / tests — behavior unchanged. Pure steps are
   tested without mocks; name tests actor + action + outcome.

## 6. Smells

| Smell | Fix |
|---|---|
| Controller sequencing load / decide / save | Move the flow into one entry function |
| `// section` comments in a long body | Each becomes a named function |
| Fetch + decide + write in one loop | resolve → plan (pure) → apply |
| `if/else` in the orchestrator | Move into a `plan*` returning actions |
| `load*` throwing "not found" | Return `null`; the orchestrator decides |
| Query inside a per-item loop | Batch in one `load*` |
| `total += 1` scattered around | Count from the plan in `report*` |
| Boolean flag parameter | Two named functions, or an action type |
| Helper that also logs / saves | One job; logs → `report*`, writes → `apply*` |
| Pure function split into one-line children used once | Inline them — extraction must buy readability |
