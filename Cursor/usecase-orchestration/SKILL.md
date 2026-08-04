---
name: usecase-orchestration
description: Backend usecase/handler pattern — readable orchestration, one step per function, pure transforms vs I/O boundaries, pseudocode-shaped flow. Use when implementing or refactoring handlers, usecases, controllers, repositories, validators, or application services in any language/framework.
---

# Usecase Orchestration

## Core idea

The **orchestrator** (usecase entry — `execute`, `handle`, `call`, etc.) is a script a human can read aloud. Each line is **one business step**. Each step is **one function that does one thing**.

```typescript
async function execute(command: DuplicateItemCommand) {
  const source = await findSourceItem(command.id)
  validateCanDuplicate(source)

  const duplicate = makeDuplicate(source)
  cleanDuplicateData(duplicate)

  const parentGroup = buildParentGroup(duplicate)
  mapGroupsToDuplicate(duplicate, parentGroup)

  await saveDuplicate(duplicate)
  await removeObsoleteRelations(duplicate.id)

  return buildDuplicateResult(duplicate)
}
```

Long orchestrators are fine when **every line is a single step call** — no nested business logic. Length is not the smell; **nesting and mixed concerns** are.

If you cannot explain the flow in pseudocode first, stop and sketch pseudocode before writing code.

## One function, one job

| Kind | Does | Does not | Examples |
|------|------|----------|----------|
| **Pure step** | Transform, validate, build in-memory shapes | I/O, DB, HTTP, queues, clock, random | `makeDuplicate`, `cleanData`, `buildParentGroup` |
| **I/O step** | Fetch or persist through repository/gateway | Business rules, branching on domain meaning | `findSourceItem`, `saveDuplicate`, `removeRelations` |
| **Orchestrator** | Call steps in order, pass outputs to inputs | Business logic, SQL, mapping details | `execute`, `handle` |

**Split when a function:**
- has `and` in its name (`fetchAndValidate` → two functions)
- both loads data and decides business outcome (except ownership validators — see below)
- returns something and also saves side effects
- needs a comment to explain its middle section

**Keep together only when** the logic is trivial (≤3 lines) and splitting hurts scanability.

## Why pure steps — simple unit tests

Pure steps exist so business rules get **easy unit tests**: input → output (or throw), **no mocks, no DB, no framework test harness**.

| Do | Why |
|----|-----|
| **Same input → same output** | Assert with literals; no flaky tests |
| **Plain objects / primitives in** | Arrange in 1–3 lines — no factory graph |
| **Return new value** instead of mutating args | One clear assertion |
| **One rule per pure function** | One happy + one failure test per function |
| **Pass time/ids as arguments** when needed | `buildExpiresAt(now)` not hidden clock — deterministic tests |

**Smell — test is hard to write:**
- needs mocking a repository → rule part should be pure; read stays in I/O step
- needs full DI / test container bootstrap → business rule trapped in orchestrator
- needs 20-line fixture → input too heavy; split or simplify
- only integration test covers a branch → extract pure step and unit test it

**Goal:** `expect(makeDuplicate(source)).toEqual(expected)` — nothing else.

Details when user asks for tests: [testing.md](testing.md).

## Where code lives

```
Transport      → HTTP/RPC/CLI only (parse input, call usecase, map response)
Orchestrator   → step order only (this skill’s focus)
Validator      → throw on invalid; may call find* + validate* children for ownership/auth
Repository     → fetch / save / delete; no business decisions
Gateway        → external APIs, message queues (I/O, no business rules)
Domain service → reusable logic tied to a specific domain/aggregate
Shared util    → generic helpers; simple types; no domain coupling
Private helper → single-use step; lives next to orchestrator
```

**Repository smell:** role checks, status transitions, derived fields computed before save.

**Orchestrator smell:** query building, nested mapping loops, business `try/catch`, more than one I/O call inside a “helper”, nested `if`/`for` business logic.

## Validators — ownership and auth

For **ownership / auth / “does this actor own this resource?”**, a parent validator may orchestrate child steps:

```typescript
async function validateUserOwnsItem(userId: string, itemId: string) {
  const item = await findItem(itemId)
  validateItemOwnedByUser(item, userId)
}
```

- Parent = `validate*` (reads like the rule name)
- Children = `find*` (I/O) + `validate*` (pure check on loaded data)
- Use when the read exists **only** to enforce that rule

Do **not** hide general business flow inside validators. Load-then-check for ownership is the exception, not the default.

## Sharing helpers

| Situation | Where |
|-----------|--------|
| Single usecase, domain-specific | Private helper next to orchestrator |
| Reused across usecases, domain-specific | Domain service |
| No specific domain, simple/generic types | `shared/`, `common/`, or package `utils/` |
| Complex domain object in/out | Domain service — not shared util |

Shared util bar: function could make sense in another feature without knowing aggregate names.

## Naming

Use **verb + business noun**. The orchestrator should read like a checklist.

| Good | Bad |
|------|-----|
| `validateCanDuplicate` | `checkData` |
| `buildGroupedItems` | `processGroups` |
| `findSourceItem` | `getData` |
| `removeObsoleteRelations` | `cleanup` |

## Function design

- **≤3 parameters.** More → small input object or the function owns too much.
- **Zero-arg closures** OK when they close over orchestrator locals without hiding repos or request context.
- Prefer **return values** over mutating shared objects unless the type is explicitly a mutable builder.

## Workflow (implement or refactor)

1. **Pseudocode** — numbered steps in plain language.
2. **One line → one function** — name each step before implementing.
3. **Label pure vs I/O** — I/O at repository/gateway; transforms pure for simple tests.
4. **Write orchestrator** — only step calls; each line one call; no nested business logic.
5. **Grill** — red-flag checklist below.

## Red flags (grill the code)

| Red flag | Fix |
|----------|-----|
| Nested business logic in orchestrator | Extract steps; one call per line |
| `process`, `handle`, `manage`, `doX` names | Rename to business verb |
| Repository applies business rules | Move to validator or pure step |
| Validator loads unrelated data | Split or move load to orchestrator |
| Helper with 4+ parameters | Input object or smaller steps |
| Same domain block in two usecases | Domain service |
| Generic helper in domain service | Move to shared util |
| Orchestrator builds SQL or DTO field-by-field | `buildX` / repository method |
| Transaction spans unrelated features | One orchestrator per transaction boundary |
| Rule only tested via integration test | Extract pure step; unit test directly |

When reviewing, **quote the orchestrator** and ask: *“Can you read this aloud as a recipe without pausing?”*

## Pure vs I/O — example

```typescript
// I/O — repository
async function findSourceItem(id: string) {
  return itemRepo.findByIdOrFail(id)
}

// Pure — validator
function validateCanDuplicate(source: Item) {
  if (source.status !== 'draft') {
    throw new CannotDuplicateError(source.id)
  }
}

// Pure — transform
function makeDuplicate(source: Item): ItemDraft {
  return { ...structuredClone(source), id: undefined, name: `${source.name} (copy)` }
}

// I/O — repository
async function saveDuplicate(draft: ItemDraft) {
  return itemRepo.save(draft)
}
```

## Framework notes

- Entry point name varies (`execute`, `handle`, `__invoke`) — same orchestration pattern.
- Inject repositories/gateways; avoid injecting many unrelated services — group by aggregate.
- Keep transport (controller, route, resolver) thin: parse → orchestrate → map response.
- Follow project conventions for errors, transactions, and async style.

Read project `AGENTS.md` or local rules when they exist — this skill is pattern only.

## Optional — testing

When the user asks for tests or test strategy, read [testing.md](testing.md). Do not apply unless requested.

## When stack idioms differ

Follow local framework conventions first. If another pattern (Result types, domain events, pipes) makes the orchestrator **more** readable, suggest it before applying.
