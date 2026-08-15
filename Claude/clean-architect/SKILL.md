---
name: clean-architect
description: Module-First Clean Architecture rules for the pluton-monorepo `apps/api` backend (NestJS 11, TypeORM, Oracle 19c, Zod). Use whenever writing, reviewing, refactoring, planning, or debugging code in apps/api — controllers, use cases, domain entities, value objects, ports, adapters, repositories, query services, mappers, DTOs, modules, errors, migrations, or tests — even if the user doesn't mention "architecture". Also use when deciding where new code belongs or whether an import is allowed.
---

# Clean Architect — apps/api

Every module in `src/modules/` follows four layers with one governing rule:

> **The Dependency Rule: dependencies only point inward. Inner layers know nothing about outer layers.**

Control flows outside → inside → outside; dependencies point only inward. Those are two different arrows — confusing them is the most common architectural mistake.

```text
presentation/ → application/ → domain/ ← infrastructure/
```

Infrastructure is an *outer* layer that depends *inward*: the domain owns the port (`BadgeRepositoryPort`); infrastructure supplies the implementation.

For the full handbook (complete examples, sequence diagrams, rationale), read [references/clean-architecture.md](references/clean-architecture.md). In-repo companions: `apps/api/AGENTS.md` (terse rules), `docs/guideline/api-architecture.md` (judgment calls), `docs/guideline/ports-and-adapters.md` (port mechanics).

## Where does this code belong?

Ask what decision the code is making:

| The code decides… | It belongs in |
|---|---|
| Whether a business state is legal | Entity / VO / domain service |
| Whether a transition is allowed | Value object (transition map) |
| What order things happen in | Use case |
| Whether the caller may do this | Use case (workflow) + guard (transport) |
| That absence is an error | Use case (query returns `null` → use case throws) |
| How data is stored or fetched | Repository / query service |
| How a row becomes an object | Mapper |
| How an error becomes a status code | Exception filter |
| What another module is allowed to see | Port + adapter |

## Which abstraction?

```text
Does the call cross a module boundary?
├─ Yes → domain/port/<name>.port.ts + application/adapter/  → returns a View
└─ No  ├─ own aggregate?  → domain/port/<name>-repository.port.ts → entity | void
       └─ a projection?   → application/query-port/ + query-service → Projection
```

Read-output suffixes are load-bearing: `Projection` (internal read model), `View` (crosses module boundary), `Result` (wrapper: pagination/counts), `Row` (raw DB row, never leaves the file).

## Import rules (dependency-cruiser, error severity — `pnpm lint:arch`)

Allowed:

```text
presentation/  → application/          (use cases only)
application/   → domain/
application/query-service/ + adapter/ → infrastructure/, typeorm   (only these two)
infrastructure/→ domain/
any module     → src/shared/, src/infrastructure/, another module's index.ts barrel
same-context submodule → sibling shared/domain/, sibling query-port/, sibling ORM entity (type-only, from ORM entity files)
```

Forbidden:

```text
domain/        → @nestjs/*, typeorm, oracledb, express, zod, nestjs-zod, nestjs-pino
domain/        → application/ | infrastructure/ | presentation/ | src/infrastructure/
application/   → presentation/ | own infrastructure/ | typeorm   (except query-service/ and adapter/)
module A       → module B's application/ | infrastructure/ | presentation/ | non-barrel files
index.ts       → anything but the Nest module + domain/port/ + domain/types/
index.ts       → any *repository*.port.ts   (never hand out write access to your aggregate)
presentation/  → adapters, query services, repositories
```

Fix errors; never loosen rules.

## Layer checklists

**💎 Domain** — pure TypeScript, zero frameworks. Entities are classes with private fields and a private constructor; two factories: `create()` mints identity (UUIDv7 inside the factory), `fromPersistence()` rebuilds trusted data. `getValue()` for mappers; no public fields or setters. Invariants validated on every path in. Method names use domain language (`hasEarnedBadge()`, not `checkBadgeRecordExists()`). Errors extend `DomainError` and name the exact failed condition (`BadgeNameRequiredError`, not `InvalidBadgeError`). No `createdAt`/`updatedAt` — audit fields belong to the ORM.

**⚙️ Application** — one use case, one workflow, one public `execute()`. Inject the *narrowest* contract (a single query-port, not the whole query service). `uow.run()` only for multi-write workflows; a single `save()` needs no UnitOfWork. Workflow failures throw `ApplicationError` subclasses (in `application/*.errors.ts`); `DomainError` propagates untouched. Query services return data, `null`, or `[]` — the use case decides whether absence is an error.

**🔧 Infrastructure** — `implements SomePort`, never `extends`. Repositories return domain entities, `Entity[]`, `null`, `void`, or `boolean` — never DTOs, projections, or rows (those belong in query services). `save(): Promise<void>`. Use the ambient transactional manager (`txEmStorage.getStore() ?? this.repository.manager`) — no transaction parameters threaded through. ORM entity class names singular (`BadgeOrmEntity`). Mappers are pure; `toDomain` calls `fromPersistence`, never `create`.

**🌐 Presentation** — controllers inject use cases only, and each method is a few lines: validate → call one use case → return the promise. Every transport input validated before the use case runs (Zod DTO, `@ParseUUIDParam`, job payloads). No `try/catch` for domain or application errors — the four exception filters translate `category` → HTTP status at the edge. OpenAPI annotations and `@Traced()` present.

**📦 Module** — the module file is the only place abstractions meet implementations. Port bindings use `useExisting` (one adapter instance can satisfy several ports). Barrel exports only the Nest module + `domain/port/` (excluding `*repository*`) + `domain/types/`. Every port a consumer needs is in `exports`.

## Function scope (see the `function-flow` skill)

Layers place code; inside a function, apply the `function-flow` skill: the body
reads top-to-bottom as named steps — details one level down.

- A use case's `execute()` is the narrative of its workflow: each line a named step
  (`load* / find*` → `resolve* / build*` → `plan*` (pure) → `apply* / save*` →
  `report*`). If it needs `// section` comments, each comment is a private method
  waiting to be extracted.
- Separate deciding from doing: decisions are pure functions returning explicit
  actions (`'create' | 'update' | 'unchanged'`); side effects live in one place.
  In this codebase the split falls out of the layers — entities/VOs decide,
  repositories do — keep the same split *within* a long method too.
- Per-item branching goes into a named helper with guard clauses; the caller only
  aggregates. Derive summaries from results, not counters mutated mid-loop.
- Validate and fail fast at the top of the workflow, never deep inside the loop.

## Ports & adapters

- Ports are **abstract classes** (they must survive to runtime to serve as DI tokens), declared in the provider's `domain/port/`, types in `domain/types/`, exported from the provider's `index.ts`.
- Verb/action names, named for the fact the consumer wants: `HasEarnedBadgePort`, not `AchievementRewardRepositoryPort`. Explicit method names, never a generic `execute()`.
- Adapters live in `application/adapter/`, may use TypeORM, and never throw `ApplicationError` — they return the fact; the consuming use case decides what it means.
- Absorb or delegate: if the logic is also used by the provider's own controller flow, the adapter delegates to the shared use case/query service; otherwise it absorbs the logic.
- **Ceremony budget** — don't add ports by imitation. Tier 1 (`personalize`, `learning-content`): full port discipline. Tier 2 (`users`, `user-activities`, `moderation`, `content-approvals`): ports by default, challenge single-consumer ones. Tier 3 (`uploads`, `creator-channel`, `channel-directory`): ceremony optional. External-system ports (object storage, YouTube, DVR) are always justified.
- Same-bounded-context submodules (inside `learning-content/`) may share `shared/domain/` primitives and import each other's `application/query-port/` directly — no ports for purely internal same-context communication.

## Queries

**Query count must not grow with row or input cardinality.** `Promise.all` over fixed independent queries (count + page) is fine; `Promise.all(items.map(…query…))` or repository calls in loops are N+1 — batch with `IN` or a join. When dismissing a `Promise.all`, say why it is bounded.

## Errors & validation

- Error codes live in `packages/shared/src/errors/codes.ts` (`<FEATURE>_<REASON>` / `<feature>.<reason>`); they are a public API contract — never rename one.
- Zod schemas are defined once in `packages/shared/src/<plural>/schemas.ts`; module DTOs re-export type + schema + `createZodDto` class.
- **Never hand-write or edit a migration.** Change `*.orm-entity.ts`, run `migration:run`, then `NAME=<PascalCase> pnpm --filter @ols/api migration:generate`, review before running.

## Testing

- Domain unit + use-case unit specs colocated (`*.spec.ts`, Vitest, fake ports — no container, no DB). Acceptance via Gherkin in `test/e2e/features/`.
- Name use-case tests as **actor + action/condition + observable business outcome** in ubiquitous language: "an admin cannot create a badge whose image no longer exists", not "throws BadgeImageAssetNotFoundError when resolveObjectKey returns null". Only the first survives a refactor.
- Skip low-value tests: no unit tests for query services or logic-free read use cases.

## Verify after every change

```sh
pnpm --filter @ols/shared build \
  && pnpm --filter @ols/api typecheck \
  && pnpm --filter @ols/api lint \
  && pnpm --filter @ols/api test \
  && pnpm --filter @ols/api lint:arch
```

Never report an architecture violation from a search hit alone — confirm against local code, port contracts, tests, and `apps/api/AGENTS.md` first.

## Common mistakes

| Mistake | Fix |
|---|---|
| Business rule written in the use case | Move to the entity or value object |
| Repository returning a DTO or a row | Use a query service |
| Controller injecting a query service | Inject a use case |
| Repository port exported from the barrel | Publish a `View` port named for the fact |
| `extends Port` | `implements Port`. Always. |
| Adapter throwing an `ApplicationError` | Return the fact; let the use case decide |
| A port added by imitation | Check the ceremony budget tier first |
| `Promise.all` over a mapped list of queries | Batch with `IN` or a join |
| Test named after a class or exception | Rename to actor + action + business outcome |
| Long `execute()` with `// section` comments, mixed decide+do | Extract named steps per the `function-flow` skill |
| Hand-edited migration | Regenerate from the entity diff |
