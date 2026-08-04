---
name: clean-architect
description: Module-First Clean Architecture guidance for any backend codebase. Use whenever designing, writing, reviewing, refactoring, or planning backend code — deciding where code belongs, structuring modules and layers (domain, application, infrastructure, presentation), designing ports and adapters, repositories, use cases, DTOs, or error handling — even if the user doesn't say "clean architecture". Also use when reviewing imports/dependencies between layers or modules, or when a codebase feels tangled and needs structure.
---

# Clean Architect (general)

A pragmatic playbook for **Module-First Clean Architecture**. Examples use TypeScript, but the rules are language- and framework-agnostic — adapt names and mechanics to the stack at hand, and defer to the repo's own conventions where they exist.

## The two organizing ideas

**Module-first**: organize by business capability (`achievements/`, `billing/`, `users/`), not by technical role (`controllers/`, `services/`, `models/`). The folder listing of `modules/` becomes the capability list of the product. A change to one module can only break that module — unless it crosses a port, which is explicit and greppable. Deleting a feature is `rm -rf` one directory plus removing one import.

**Clean architecture inside each module**: four layers with one governing rule.

> **The Dependency Rule: dependencies only point inward. Inner layers know nothing about outer layers.**

```text
presentation/ → application/ → domain/ ← infrastructure/
```

Infrastructure is an *outer* layer that depends *inward*: the domain owns the interface (the port); infrastructure supplies the implementation. This inversion is what lets you swap the database, queue, or storage without the domain noticing.

Control flows outside → inside → outside; dependencies point only inward. Those are two different arrows — confusing them is the most common architectural mistake.

## Anatomy of a module

```text
modules/<capability>/
├── domain/           💎 pure business rules — zero frameworks
│   ├── entity/       aggregates: classes with identity + behavior
│   ├── value-object/ immutable concepts, state-transition maps
│   ├── service/      rules coordinating several entities/VOs
│   ├── port/         abstract contracts the outer layers must satisfy
│   ├── types/        port inputs / results / views
│   └── *.errors.ts   domain errors
├── application/      ⚙️ orchestration
│   ├── use-cases/    one workflow each, one public execute()
│   ├── query-port/   narrow read contracts (internal)
│   ├── query-service/ read projections (ORM/SQL allowed here)
│   ├── adapter/      implementations of ports published to other modules
│   ├── dto/          request/response shapes
│   └── *.errors.ts   workflow errors
├── infrastructure/   🔧 concrete technology
│   ├── entity/       ORM entities
│   ├── mapper/       ORM row ⇄ domain object (pure functions)
│   └── repository/   command-side persistence
├── presentation/     🌐 transport: HTTP controllers, queue processors
├── <capability>.module.ts   DI wiring — the only place abstractions meet implementations
└── index.ts          public barrel — the module's entire public API
```

A capability too large for one module becomes a **bounded context**: a directory of submodules sharing domain language and a `shared/domain/` for common primitives. Submodules inside one context may import each other's query contracts directly; everything outside talks through published ports only.

## Layer responsibilities

**💎 Domain — be right about the business, forever, regardless of technology.**
No framework, ORM, HTTP, or validation-library imports. Entities are classes (not interfaces) with private fields and a private constructor — an interface is a shape; an entity is a shape *plus the rules that keep it valid*. Two factories: `create()` mints new identity (generate the ID here — the domain owns identity), `fromPersistence()` rebuilds trusted data without re-deciding it. A `getValue()` snapshot for mappers; never public fields or setters. Value objects encode state machines as one transition table instead of `if` chains scattered across use cases. Method names use the team's domain language: `hasEarnedBadge()`, not `checkBadgeRecordExists()`. Errors name the exact failed condition: `BadgeNameRequiredError`, not `InvalidBadgeError`. Audit fields (`createdAt`/`updatedAt`) belong to the ORM, not the domain.

**⚙️ Application — orchestrate one workflow.**
Decide *what happens in what order*; delegate *what is allowed* to the domain and *how it is stored* to ports. One use case = one workflow = one public `execute()`. Inject the **narrowest** contract that does the job. Wrap multi-write workflows in a unit of work; a single atomic save needs none. Make workflow decisions: authorization context, duplicates, invalid workflow state, not-found → error. Query services are the read side — response DTOs are usually not domain entities (joins, pagination, cross-module composition no aggregate should carry); they return data, `null`, or `[]`, and the *use case* decides whether absence is an error. Only `query-service/` and `adapter/` may touch the ORM directly — reads and cross-module port implementations legitimately need queries; everything else in this layer names abstractions only.

**🔧 Infrastructure — make the ports real.**
Implement repository ports; map rows ⇄ domain objects with pure mappers (`toDomain` calls `fromPersistence`, never `create` — persisted data keeps its identity and is trusted). Repositories return domain entities, `null`, `void`, or `boolean` — never DTOs, projections, or raw rows; the moment a repository returns a DTO it has become an untested read model. `save()` returns `void` — the caller already has the entity. Join the ambient transaction (e.g. async-local storage) so no transaction parameter threads through use cases. No business or workflow decisions here.

**🌐 Presentation — translate transport, nothing more.**
Controllers inject use cases only — never query services, repositories, or adapters. Validate every transport input (params, query, body, job payload) before the use case runs. A controller method longer than a few lines is usually holding a workflow decision that belongs in the use case. No `try/catch` for domain or application errors — exception filters/middleware translate error *category* → status code at the edge, so the throw site never knows about HTTP.

## Where does this code belong?

Ask what decision the code is making:

| The code decides… | It belongs in |
|---|---|
| Whether a business state is legal | Entity / VO / domain service |
| Whether a transition is allowed | Value object (transition map) |
| What order things happen in | Use case |
| Whether the caller may do this | Use case (workflow) + guard (transport) |
| That absence is an error | Use case |
| How data is stored or fetched | Repository / query service |
| How a row becomes an object | Mapper |
| How an error becomes a status code | Exception filter / edge middleware |
| What another module is allowed to see | Port + adapter |

## Ports & adapters

A **port** is a contract owned by the provider's domain; an **adapter** is the provider's implementation. Consumers depend on the port; DI supplies the adapter. In runtimes where interfaces vanish at compile time (TypeScript), use abstract classes so the contract can double as a DI token.

One question decides which abstraction:

```text
Does the call cross a module boundary?
├─ Yes → domain/port/ + application/adapter/     → returns a View (never a domain entity or repository)
└─ No  ├─ own aggregate?  → repository port       → entity | void
       └─ a projection?   → query-port + query-service → Projection
```

Port rules: named for the **fact the consumer wants**, not for your storage (`HasEarnedBadgePort`, not `RewardRepositoryPort`); verb/action names with explicit methods, never a generic `execute()`; `implements`, never `extends`. Adapters return facts and never throw workflow errors — the consuming use case decides what a result means. If the adapter's logic is also used by the provider's own flow, delegate to the shared use case; otherwise absorb it.

**Read-output naming is load-bearing**: `Projection` (internal read model), `View` (crosses a module boundary), `Result` (wrapper: pagination, counts), `Row` (raw DB row — never leaves the file).

**The ceremony budget.** Ports buy future optionality, not present safety. Spend where the domain is volatile or the module is a real extraction candidate; challenge single-consumer ports on stable, generic modules. Always justified: ports to external systems (storage, third-party APIs) — the problem is stable but the provider is not. Never add a port because the neighbouring module has one; ask what change it makes cheap and whether that change is likely.

**The public barrel** (`index.ts`) exports only: the DI module, published ports, and their types. Not entities, not errors, not use cases, not repositories — exporting a repository port hands another module write access to your aggregate.

## Import rules

Allowed: `presentation → application (use cases only)`; `application → domain`; `query-service/ and adapter/ → infrastructure + ORM`; `infrastructure → domain`; any module → shared kernel, process-wide infrastructure, and other modules' barrels.

Forbidden: domain → any framework/ORM or any outer layer; application → presentation, own infrastructure, or the ORM (outside the two exemptions); module A → module B's internals or non-barrel files; presentation → adapters, query services, repositories.

**Enforce mechanically.** Architecture that is only documented decays. Use an import-boundary linter (dependency-cruiser, ArchUnit, import-linter, deptrac…) at error severity in CI. Fix errors; do not loosen rules.

## Cross-cutting concerns

- **Shared kernel** (`shared/`) holds framework-agnostic building blocks; process-wide technical adapters live in a top-level `infrastructure/`. Neither may import from `modules/` — a shared component that knows about one module isn't shared; it belongs to that module.
- **Errors** are typed and categorized: `DomainError` for invariants, `ApplicationError` for workflow failures; a `category` field (not the throw site) maps to the transport status at the edge. Error codes are a public API contract — never rename one.
- **Validation**: one schema per shape, defined once, validated at the transport edge, typed all the way down.
- **Queries**: query count must not grow with row or input cardinality. Fixed independent queries in parallel are fine; a query per mapped item is N+1 — batch or join.

## Testing strategy

- Domain unit tests: invariants, transitions, calculations — pure, colocated, milliseconds.
- Use-case unit tests: workflow orchestration with fake ports — the fakes are one-liners precisely because dependencies are abstractions.
- Acceptance tests: externally visible behavior against a real database.
- Name use-case tests as **actor + action/condition + observable business outcome**: "an admin cannot create a badge whose image no longer exists", not "throws NotFoundError when resolve returns null". Only the first survives a refactor.
- Skip low-value tests: query services and logic-free read paths just assert that a mock returns what it was told.

## Common mistakes

| Mistake | Fix |
|---|---|
| Business rule written in the use case | Move to the entity or value object |
| Repository returning a DTO or a row | Use a query service |
| Controller injecting a query service | Inject a use case |
| Repository port exported from the barrel | Publish a `View` port named for the fact |
| Adapter throwing a workflow error | Return the fact; let the use case decide |
| A port added by imitation | Check the ceremony budget first |
| Query per item in a loop / mapped `Promise.all` | Batch with `IN` or a join |
| Test named after a class or exception | Rename to actor + action + business outcome |
| Duplicated state-transition `if` chains | One transition map in a value object |
| Shared kernel importing a module | Move the component into that module |

## Worked patterns

For full code examples — entity with dual factories, use case, repository with ambient transaction, mapper, port + adapter + DI wiring, and test fakes — read [references/patterns.md](references/patterns.md).
