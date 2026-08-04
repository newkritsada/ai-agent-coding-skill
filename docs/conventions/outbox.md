## Outbox

Use the outbox for consistency-critical background commands that are caused by a
database write. The business rows and outbox row must be written in the same
`UnitOfWork` when correctness depends on both committing together.

Do not use the outbox for high-frequency analytics signals where tiny drift is
acceptable, such as media view counters. Use a lighter queue/buffer path for
those signals.

### Message shape

- Outbox rows are generic: `type`, `payload_json`, `aggregate_type`,
  `aggregate_id`, status, attempts, timestamps, and error details.
- IDs are app-generated UUIDv7 strings.
- `payload_json` is an object payload stored as JSON-backed CLOB for Oracle 19c.
- `aggregate_type` and `aggregate_id` are required for every message.
- Message `type` strings and payload schemas are owned by the feature that owns
  the command.
- Payloads should be IDs only. Processors refetch current database state.

### Delivery

The outbox relay publishes pending rows to BullMQ and marks a row `PUBLISHED`
after BullMQ accepts the job. It does not wait for job completion.

Delivery is at least once. A relay crash after `queue.add()` succeeds but before
the outbox row is marked `PUBLISHED` can publish the same command again. Use a
deterministic BullMQ `jobId` based on the outbox row ID, but never rely on that
as exactly-once delivery.

### Relay deployment

Run exactly one outbox relay replica in v1. The v1 relay does not claim rows
with database leases. If multiple relay replicas run at the same time, duplicate
publishing is possible.

The relay is a dedicated process:

```text
main.ts          -> API
worker.ts        -> BullMQ processors
outbox-relay.ts  -> Oracle outbox -> BullMQ
```

### Processors

Processors MUST be idempotent. BullMQ and the outbox relay are at-least-once
systems, so a job may be delivered more than once. Processors must use stable
IDs, refetch current database state, and safely no-op or resume when work has
already completed.

### Retention

Outbox rows are retained indefinitely for audit/debugging. They are not a
general event-sourcing log. Replaying an outbox message is only allowed when
that specific message type documents replay-safe behavior.

