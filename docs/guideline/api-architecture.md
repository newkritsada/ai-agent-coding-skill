# API Architecture Judgment

Use this when a change needs architecture judgment beyond the quick rules in
`apps/api/AGENTS.md`. For port/adapters mechanics, read
`apps/api/docs/guideline/ports-and-adapters.md`.

## Responsibility Test

Ask what decision the code is making:

- **Business invariant or transition?** Put it in an entity, value object, or
  domain service. Use cases should call domain behavior, not duplicate it.
- **Workflow decision?** Put it in the use case: authorization context,
  duplicate inputs, empty inputs, invalid workflow state, and not-found mapping.
- **Command persistence?** Use a repository to rebuild and save domain objects.
  Do not turn repositories into read-model assemblers.
- **Read projection?** Use a query service returning DTO/view data, `null`, or
  `[]`. The use case decides whether absence is an error.
- **Cross-module fact or action?** Use a provider-owned port and adapter. Do not
  import another module's repositories, use cases, entities, or application
  errors.
- **Shared orchestration?** Use an application service only when multiple use
  cases share workflow. It should still delegate business rules to domain
  objects and persistence to ports/repositories.

## Ceremony Budget

Ports and adapters exist to keep cross-module coupling weak enough that a module
could later move out on its own. That is worth paying for where the domain is
volatile or the module is a real extraction candidate — not everywhere by
default. One team on one deployable means the boundary itself is cheap to cross;
the port is buying future optionality, not present safety.

| Tier | Modules | Rule |
|---|---|---|
| 1 — full discipline | `personalize`, `learning-content` | Volatile core. Every cross-module edge is a port returning a `View`. Spend here. |
| 2 — ports by default | `users`, `user-activities`, `moderation`, `content-approvals` | Keep ports; challenge single-consumer ones on review. |
| 3 — ceremony optional | `uploads`, `creator-channel`, `channel-directory` | Generic, stable, at most one consumer, no extraction intent. A port here buys little. |

Always justified regardless of tier: **external-system ports**. The problem
("store a file") is stable but the provider is not. Keep
`upload-object-storage.port.ts`, `media-object-storage.port.ts`, and the YouTube
lookup / DVR adapters.

Don't add a port because the neighbouring module has one. Ask what change it
makes cheap, and whether that change is likely.

## Query Shape Test

`Promise.all` is not a violation by itself. Classify the database shape:

- **Valid:** fixed, independent queries such as count plus paginated rows for a
  table/list view.
- **Likely N+1:** `Promise.all(items.map(...query...))`, repository/query
  service calls inside loops, or any read where query count grows with rows,
  IDs, or child collections.
- **Likely consolidatable:** multiple same-domain reads for one projection that
  could be one join, subquery, or batched `IN` query without crossing ownership
  boundaries.
- **Needs context:** cross-module ports, external providers, cache warmups, and
  writes. Check the port contract, side effects, and cardinality before
  reporting an N+1 issue.

When reporting a query-shape finding, name the cardinality driver and the better
shape. When skipping a `Promise.all` hit, say why it is bounded or intentionally
separate.

## Evidence Standard

Do not report a violation from a search hit alone. Confirm it against local
code, port contracts, feature scenarios, tests, `apps/api/AGENTS.md`, and the
focused guideline for that area. `lint:arch` findings are strong leads, but
human judgment still decides whether the current code is acceptable.
