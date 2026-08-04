# Ports & Adapters

## Which Abstraction?

One question decides it: **does the call cross a module boundary?**

| Need | Crosses a boundary? | Use | Returns |
|---|---|---|---|
| Read a fact or trigger an action in another module | Yes | `domain/port/<name>.port.ts` + `application/adapter/` | `View` — never a domain entity, never a repository |
| Read a projection inside your own module/context | No | `application/query-port/<name>.query-port.ts` + `*.query-service.ts` | `Projection` |
| Load or save your own aggregate | No | `domain/port/<name>-repository.port.ts` | Domain entity / `void` |

Repository ports are **internal persistence contracts**. Never export one from
`index.ts`. A cross-module caller that needs persisted data needs a `View` port
named for the fact it wants — not your aggregate, and not your repository.

Everything below is detail on these three rows.

## Hard Rule

No module imports another module's `application/`, `infrastructure/`, or `presentation/`.
Cross-module calls go through provider `domain/port/` only.

```text
Controller -> Use Case -> Query Service / Repository
                         ^ adapters may reuse these
Other Module -> Port <- Adapter
```

## Layers

| Layer | Job | Called by |
|---|---|---|
| Controller | HTTP + validation only. No query service/adapters. | NestJS |
| Use case | Orchestrate app flow. Commands use repos. Reads use query services. | Controller |
| Query port | Narrow read contract inside a module/context. Abstract class DI token. | Use case |
| Query service | Read DTO/view projection. ORM allowed. Ports allowed for composition. | Use case, adapter |
| Repository | Command-side domain loading/saving. ORM -> domain mapping. Internal — never exported. | Use case, adapter |
| Adapter | Implements cross-module port. Real logic or delegates. | Nest DI |
| Port | Cross-module contract. Abstract class DI token. | Consumer modules |

## Read vs Write

| Need | Use | Return |
|---|---|---|
| Command save/mutate | `*.repository.port.ts` | Domain entity / void |
| Command lookup (`findOne`, `findById`) | repository | Domain entity |
| Read endpoint DTO/view | `application/*.query-service.ts` | Response DTO / view |

Use **repository** when caller needs domain behavior: invariant, command precondition, mutation, save. Repo may query many rows to rebuild domain entity.

Use **query service** when caller needs read DTO/view, not domain behavior. Use for filters, pagination, sorting, joins, audit fields, response-only fields, cross-module composition.

GET-by-id may use query service when response differs from domain entity. Command `findById` stays repository.

## Ports

Structure:

```text
provider/domain/types/<port-name>.types.ts  # input/result/view types
provider/domain/port/<port-name>.port.ts    # abstract class only
provider/index.ts                           # exports module + ports/types only
```

Rules:

- One port per domain concept.
- Verb/action names: `RegisterAssetPort`, `ResolveAssetsPort`, `VerifyMediaExistsPort`.
- Method names explicit. Avoid generic `execute()`.
- Abstract class, not interface. `implements Port`, never `extends Port`.
- Port file declares abstract class only. Types live in `domain/types/`.
- No types file needed for primitive-only contracts.

## Adapters

Adapters live in `application/adapter/`.
Adapters may import ORM/TypeORM when implementing cross-module ports.
Controllers never import adapters.

Adapters do not own app/HTTP errors. They fetch/project/persist and may throw
only infra or adapter-local invariant errors. Use cases decide whether adapter
results should become `ApplicationError`.

Absorb vs delegate:

| Shared with controller use case? | Adapter does |
|---|---|
| No | Absorb logic. Delete unused use case/query service. |
| Yes | Delegate to shared use case/query service. |

Adapter rules:

- `implements Port`, never `extends Port`.
- Constructor param names keep `Port` suffix: `registerAssetPort`.
- No empty passthrough unless sharing real logic.

DI pattern:

```typescript
providers: [
  AssetAdapter,
  { provide: RegisterAssetPort, useExisting: AssetAdapter },
  { provide: ResolveAssetsPort, useExisting: AssetAdapter },
],
exports: [RegisterAssetPort, ResolveAssetsPort],
```

## Decision Tree

```text
Need cross-module call?
  -> define port in provider domain/port/
  -> define types in provider domain/types/
  -> export from provider index.ts
  -> consumer imports from provider barrel

Implementing port?
  -> used by controller use case too?
      yes -> adapter delegates
      no  -> adapter absorbs
```
