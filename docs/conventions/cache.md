# Cache

Redis is a best-effort read-model cache. It must never become required for API
correctness.

## Where to cache

- Cache at the read use-case/application layer.
- Cache final JSON-safe response DTOs, not ORM rows or domain entities.
- Do not cache command validation/precondition reads.
- Do not cache personalized or role-shaped responses unless the key explicitly
  includes every permission-relevant scope such as user, role, tenant, locale, or
  audience.

## Freshness

- Static/reference read models may use TTL-only caching.
- CRUD read models use TTL plus invalidation.
- Paginated/filterable list caches use cache-family generations. Mutations bump
  the family generation instead of scanning and deleting every list variant; old
  generations become unreachable and expire by TTL.
- Detail caches use exact keys and exact deletes.
- V1 does not wire cross-module invalidation. If a response embeds summaries
  from another module, the short TTL bounds that staleness.

## Operational rules

- TTL is mandatory for every cached value write. Cache-family generation
  counters are finite metadata and intentionally persist across value expiry.
- `CacheService` adds small TTL jitter centrally so hot keys created together do
  not all expire in the same second and stampede the database.
- Redis failures are logged and swallowed. Reads fall back to the loader, and
  write/invalidation failures do not fail user requests.
- Do not cache `null` or `undefined` detail misses.
- Empty successful list DTOs may be cached.
- Cacheable timestamps should be ISO strings so fresh and cached responses have
  the same JSON shape.
