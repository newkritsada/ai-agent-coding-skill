## Background jobs (BullMQ)

Two processes, one codebase: `main.ts` (API) + `worker.ts` (consumer). Both bootstrap same feature modules — controllers register in API, processors in worker. BullMQ via `@nestjs/bullmq`. **Producer ≠ consumer** — opposite layers, dep-cruiser enforces.

For DB-triggered background commands that must commit atomically with business
writes, use the outbox relay pattern documented in `docs/conventions/outbox.md`.
Outbox delivery is at least once, so processors MUST be idempotent.

- **Queue port** — `domain/<verb>.job-queue.ts`, `abstract class`. Like a repo port. Use cases depend on it.
- **Producer** — `infrastructure/queue/<verb>.bullmq.producer.ts` implements port via `@InjectQueue(QUEUE_NAME)`. Wraps `queue.add`.
- **Consumer** — `presentation/processors/<verb>.processor.ts` extends `WorkerHost`, `@Processor(QUEUE_NAME)`. Parses `job.data` with job DTO schema → calls process-side use case. **Never** import repo directly.
- **Two use cases per op**: `enqueue-<verb>.use-case.ts` (controller) + `process-<verb>.use-case.ts` (processor). Both via application/domain.
- **Queue name**: kebab `<feature-plural>-<verb>` (`videos-transcode`, `emails-send`). `<verb>.queue.config.ts` next to producer exports `QUEUE_NAME`, `defaultJobOptions`, `workerOpts` — producer + processor import same constant.
- **Payload = IDs only**. Consumer re-fetches via repo. Snapshot data → staleness, Redis bloat, hard schema evolution. Exceptions: idempotency keys, trace IDs.
- **Payload schemas** — `application/dto/jobs/<verb>.job.dto.ts` (Zod). Validate at `queue.add` + at receive.
- **Idempotency required** — processors must safely handle duplicate delivery.
  Refetch by stable IDs and no-op/resume based on current DB state.
- **Defaults** per queue: `attempts`, `backoff: { type: "exponential", delay }`, `removeOnComplete: { age, count }`, `removeOnFail: { age }`. Failed-job retention 7 days for debugging.
- **Concurrency**: CPU-bound (ffmpeg) → 1/pod. I/O-bound (email) → 20+. Set on Worker, not global.
- **Lifecycle**: both call `app.enableShutdownHooks()` → clean Worker close on SIGTERM. k8s: `terminationGracePeriodSeconds` ≥ longest job (300+ for transcoding).
