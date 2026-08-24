---
name: clean-architect
description: Clean Architecture as a portable concept — layering, the dependency rule, ports & adapters, where code belongs. Use when writing, reviewing, refactoring, or planning backend code (NestJS, Go, Elysia, or any stack), or when deciding where new code belongs or whether a dependency/import is allowed. Adapt to each repo's existing structure; apply as principles when the repo can't follow the full shape.
---

# Clean Architect

One governing rule:

> **The Dependency Rule: dependencies only point inward. Inner layers know nothing about outer layers.**

Control flows outside → inside → outside; dependencies point only inward. Two different arrows — confusing them is the most common architectural mistake. Infrastructure is an *outer* layer that depends *inward*: the domain owns the port (interface/contract); infrastructure supplies the implementation. That inversion is what makes the stack swappable.

```text
presentation → application → domain ← infrastructure
```

| Layer | Job | Never |
|---|---|---|
| 💎 Domain | Be right about the business, forever. Entities, value objects, domain services, ports, domain errors. | Import frameworks, ORM, HTTP, validation libs, or any outer layer |
| ⚙️ Application | Orchestrate one workflow per use case: sequence, transactions, workflow errors. | Duplicate business rules; import presentation; touch the ORM (except read/query services and adapters) |
| 🔧 Infrastructure | Make the ports real: repositories, mappers, ORM entities, external clients. | Make business or workflow decisions; return DTOs/rows from a command repository |
| 🌐 Presentation | Translate transport ↔ use case: routes, validation, auth guards. | Hold business rules; call repositories/query services directly; catch domain errors (translate at the edge) |

## Adapting to the repo (this skill is a concept, not a template)

Every repo differs — NestJS modules, Go packages, Elysia plugins, flat services. **Match the repo's existing structure and idiom; apply the closest workable form of each principle.** Priority when full application isn't possible:

1. Dependency rule (business logic imports no framework/IO) — never compromise
2. Deciding vs doing separated (domain decides, infrastructure does)
3. Depend on abstractions at boundaries (interfaces/ports), bound in one composition place
4. One workflow = one use case / handler function
5. Folder shape, naming suffixes, ceremony — fully negotiable; follow the repo

Stack mapping examples: NestJS → abstract-class ports as DI tokens, module file wires bindings. Go → interfaces defined in the consumer/domain package, wiring in `main`/`wire`. Elysia/functional → plain functions + dependency parameters or a small container; "entity" may be a validated constructor + pure functions. If the repo has no layers at all, still separate: pure business functions ← orchestrating handler ← IO at the edges.

## Where does this code belong?

Ask what decision the code is making:

| The code decides… | Belongs in |
|---|---|
| Whether a business state is legal | Entity / value object / domain service |
| Whether a transition is allowed | Value object (explicit transition map, not `if` chains) |
| What order things happen in | Use case |
| Whether the caller may do this | Use case (workflow) + guard (transport) |
| That absence is an error | Use case (queries return `null`/empty; use case throws) |
| How data is stored or fetched | Repository / query service |
| How a row becomes an object | Mapper (pure) |
| How an error becomes a status code | Filter/middleware at the edge |
| What another module may see | Port + adapter |

## Key rules per layer

**Domain** — pure language code, zero frameworks. Entities carry behavior + invariants, validated on every path in (private/controlled construction). Two ways in: `create()` mints new identity (ID generated in the domain), `fromPersistence()`/rehydrate rebuilds trusted data without re-minting identity. Methods named in business language (`hasEarnedBadge()`, not `checkRecordExists()`). Errors name the exact failed condition (`BadgeNameRequiredError`, not `InvalidBadgeError`). Audit fields (`createdAt`/`updatedAt`) belong to persistence, not the domain.

**Application** — one use case, one workflow, one public entry method. Inject the *narrowest* contract that does the job (a single query port, not a whole service). Transactions wrap only multi-write workflows; a single save needs none. Workflow failures → application errors; domain errors propagate untouched. Neither error type knows HTTP — a `category`/`code` on the error lets the edge map status. **Command/query split:** command side returns domain entities or `void`; read side (query services) returns projections shaped for the response — a use case decides whether absence is an error.

**Infrastructure** — `implements` the port, never inherits behavior from it. Command repositories return domain entities, `null`, `void`, or `boolean` — never DTOs, projections, or raw rows (those are the read side's job). `save()` returns nothing — the caller already has the entity. Mappers are pure; row→domain uses the rehydrate factory, never `create()`. Transactions ambient/contextual, not threaded through signatures.

**Presentation** — handlers inject use cases only and stay a few lines: validate input → call one use case → return. Every transport input validated before the workflow runs. No `try/catch` for domain/application errors — one edge translator maps error category → status code.

**Composition** — exactly one place binds abstractions to implementations (module file, `main`, container setup). A module's public surface exports only its entry point + published ports/types — **never repository ports** (that hands out write access to your aggregate).

## Ports & adapters

- Port = contract owned by the **provider's domain**, named for the fact the consumer wants (`HasEarnedBadgePort`), with explicit method names — never generic `execute()`. Cross-module reads return a `View`/plain data, never a domain entity or repository.
- Adapter = provider's implementation; it returns the fact and never decides what the fact means — the consuming use case does. If the logic is shared with the provider's own flow, delegate; otherwise absorb it.
- **Ceremony budget:** don't add ports by imitation. Full port discipline where the domain is volatile or extraction is plausible; skip ceremony for stable, single-consumer, internal edges. External systems (storage, third-party APIs) always deserve a port — the problem is stable, the provider isn't.
- Same-bounded-context submodules may share domain primitives and internal query contracts directly — no ports for code that ships together.

## Queries

**Query count must not grow with row or input cardinality.** `Promise.all`/goroutines over a *fixed* set of independent queries is fine; a query per mapped item or inside a loop is N+1 — batch with `IN` or a join. When dismissing one, say why it's bounded.

## Function scope → apply the `function-flow` skill

Layers place code between files; inside a function, `function-flow` governs:

- A use case's body is the narrative of its workflow — named steps (`load → resolve/build → plan (pure) → apply/save → report`). `// section` comments mark helpers waiting to be extracted.
- Separate deciding from doing *within* a function too: decisions are pure and return explicit actions; side effects live in one place.
- Per-item branching → named helper with guard clauses; caller only aggregates. Derive summaries from results, not counters mutated mid-loop.
- Validate and fail fast at the top of the workflow, never deep inside a loop.

## Testing

- Domain + use-case unit tests need no DB/container — abstractions make fakes one-liners. That cheapness is the architecture's proof.
- Name use-case tests as **actor + action/condition + observable business outcome** ("an admin cannot create a badge whose image no longer exists"), never after classes or exceptions — only the first survives a refactor.
- Skip low-value tests: no units for query services or logic-free read paths (they only assert the mock).

## Working in a repo

- Discover the repo's conventions first (existing modules, lint/arch tooling, AGENTS/CLAUDE docs); imitate the nearest good example rather than importing this skill's folder names.
- If the repo enforces boundaries (dependency-cruiser, arch lint, import rules): **fix errors, never loosen rules.** Run the repo's verify pipeline after every change.
- Never report an architecture violation from a search hit alone — confirm against the actual code, contracts, and tests.

## Common mistakes

| Mistake | Fix |
|---|---|
| Business rule in the use case | Move to entity / value object |
| Command repository returning a DTO or row | Move to the read side (query service) |
| Handler calling repository/query service directly | Inject a use case |
| Repository port in the public surface | Publish a narrow read port named for the fact |
| Adapter deciding a missing fact is an error | Return the fact; the use case decides |
| Port added by imitation | Check the ceremony budget first |
| Query per mapped item / in a loop | Batch with `IN` or a join |
| Test named after a class or exception | Actor + action + business outcome |
| Long workflow body with `// section` comments | Extract named steps per `function-flow` |
| Domain importing framework "just for a type" | Define the type in the domain; map at the edge |
