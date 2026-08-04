# Clean Architect — worked patterns

Concrete reference implementations for the rules in SKILL.md. TypeScript with a NestJS-style DI flavor; translate idioms to your stack (the *shapes* are what matter).

## Contents

1. [Domain entity with dual factories](#1-domain-entity-with-dual-factories)
2. [Value object as a transition map](#2-value-object-as-a-transition-map)
3. [Use case](#3-use-case)
4. [Repository with ambient transaction](#4-repository-with-ambient-transaction)
5. [Pure mapper](#5-pure-mapper)
6. [Published port + adapter + DI wiring](#6-published-port--adapter--di-wiring)
7. [Query port + query service](#7-query-port--query-service)
8. [Error bases and edge translation](#8-error-bases-and-edge-translation)
9. [Test fakes](#9-test-fakes)
10. [Flow of control, end to end](#10-flow-of-control-end-to-end)

---

## 1. Domain entity with dual factories

```typescript
export class Badge {
  private _id: string;
  private _name: string;
  private _imageAssetId: string | null;

  private constructor(props: BadgeProps) {
    Badge.validateName(props.name);          // invariant on EVERY path in
    this._id = props.id;
    this._name = props.name;
    this._imageAssetId = props.imageAssetId;
  }

  static create(props: CreateBadgeProps): Badge {
    return new Badge({ ...props, id: uuidv7() });   // domain owns identity
  }

  static fromPersistence(props: BadgeProps): Badge {
    return new Badge(props);                        // rebuild, keep identity
  }

  hasImage(): boolean { return this._imageAssetId !== null; }

  update(props: UpdateBadgeProps): void {
    Badge.validateName(props.name);
    this._name = props.name;
    this._imageAssetId = props.imageAssetId;
  }

  getValue(): BadgeProps {
    return { id: this._id, name: this._name, imageAssetId: this._imageAssetId };
  }

  private static validateName(name: string): void {
    if (!name.trim()) throw new BadgeNameRequiredError();
  }
}
```

Why this shape: the private constructor means there is no way to build a `Badge` that bypasses `validateName` — the invalid state is unrepresentable. Two factories, two intents: `create()` mints a new identity; `fromPersistence()` rebuilds one that already exists and is trusted. `getValue()` lets mappers read the whole object without the entity leaking public setters.

Application-generated, time-ordered IDs (UUIDv7 or equivalent) minted inside `create()` mean a use case can reference `badge.getId()` before anything touches the database, and correlate events without a round trip.

## 2. Value object as a transition map

```typescript
const STATUS_TRANSITIONS = {
  [Status.Draft]: {
    [Action.Publish]: Status.Published,
  },
  [Status.Published]: {
    [Action.Flag]: Status.Flagged,
    [Action.Unpublish]: Status.Unpublished,
    [Action.Edit]: Status.PendingEdit,
  },
  // ...
} satisfies TransitionMap;
```

The legal transitions live in one table. Adding a status means editing one file, and the compiler finds every gap. Without the VO, this knowledge duplicates across every use case that touches status — the shotgun-surgery anti-pattern.

## 3. Use case

```typescript
@Injectable()
export class CreateBadgeUseCase {
  constructor(
    private readonly badgeRepo: BadgeRepositoryPort,           // abstraction
    private readonly resolveAssetPort: ResolveAssetObjectKeyPort, // another module's port
    private readonly uow: UnitOfWork,
  ) {}

  async execute(input: CreateBadgeInput): Promise<{ id: string }> {
    if (input.imageAssetId) {
      const objectKey = await this.resolveAssetPort.resolveObjectKey(input.imageAssetId);
      if (!objectKey) throw new BadgeImageAssetNotFoundError(input.imageAssetId);
    }

    return this.uow.run(async () => {
      const badge = Badge.create({ name: input.name, imageAssetId: input.imageAssetId ?? null });
      await this.badgeRepo.save(badge);
      return { id: badge.getId() };
    });
  }
}
```

Every dependency is an abstraction; nothing in this file knows which database exists. Note the division of decisions: a missing asset is a *workflow* decision (the badge concept is valid without knowing about asset storage) so the use case throws an application error; an empty name is a *business invariant* so the entity throws a domain error — and that rule holds no matter which use case calls it.

Use the unit of work only for multi-write workflows; a single `repository.save()` is atomic on its own.

## 4. Repository with ambient transaction

```typescript
@Injectable()
export class BadgeRepository implements BadgeRepositoryPort {
  constructor(
    @InjectRepository(BadgeOrmEntity)
    private readonly repository: Repository<BadgeOrmEntity>,
  ) {}

  private get manager(): EntityManager {
    return txStorage.getStore() ?? this.repository.manager;  // join ambient tx if present
  }

  async findById(id: string): Promise<Badge | null> {
    const orm = await this.manager.findOne(BadgeOrmEntity, { where: { id } });
    return orm ? BadgeMapper.toDomain(orm) : null;
  }

  async save(badge: Badge): Promise<void> {
    await this.manager.save(BadgeOrmEntity, BadgeMapper.toPersistence(badge));
  }
}
```

The `manager` getter is the whole transaction story: if a unit of work is running, async-local storage holds its transactional manager and every write in the call tree joins that transaction automatically — no transaction parameter threads through the use case.

Repository return contract:

| Method kind | Returns |
|---|---|
| Aggregate loader (`findById`, `findByIds`) | Domain entity, `Entity[]`, or `null` |
| Persistence (`save`, `delete`) | `void` |
| Existence fact (`existsBy…`) | `boolean` |

Anything else — projections, DTOs, raw rows — belongs in a query service.

## 5. Pure mapper

```typescript
export const BadgeMapper = {
  toDomain(orm: BadgeOrmEntity): Badge {
    return Badge.fromPersistence({ id: orm.id, name: orm.name, imageAssetId: orm.imageAssetId });
  },

  toPersistence(badge: Badge): BadgeOrmEntity {
    const value = badge.getValue();
    return Object.assign(new BadgeOrmEntity(), value);
  },
};
```

`toDomain` calls `fromPersistence`, not `create` — persisted data is trusted to already be valid and must keep its existing identity. Mappers are pure functions: no I/O, no decisions.

## 6. Published port + adapter + DI wiring

```typescript
// provider/domain/port/has-earned-badge.port.ts — abstract class ONLY
/** Has the given user earned the given badge? */
export abstract class HasEarnedBadgePort {
  abstract hasEarnedBadge(user: UserInfo, badgeId: string): Promise<boolean>;
}
```

```typescript
// provider/application/adapter/achievement-badge.adapter.ts
@Injectable()
export class AchievementBadgeAdapter implements HasEarnedBadgePort {
  constructor(private readonly rewardRepo: AchievementRewardRepositoryPort) {}

  async hasEarnedBadge(user: UserInfo, badgeId: string): Promise<boolean> {
    const actorType = resolveActorType(user.role);
    if (!actorType) return false;
    return this.rewardRepo.existsByActorAndBadge(actorType, user.id, badgeId);
  }
}
```

```typescript
// provider module wiring — the ONLY place abstractions meet implementations
providers: [
  AchievementBadgeAdapter,
  { provide: HasEarnedBadgePort, useExisting: AchievementBadgeAdapter },
],
exports: [HasEarnedBadgePort],
```

```typescript
// provider/index.ts — the complete public API
export { AchievementModule } from "./achievement.module";
export { HasEarnedBadgePort } from "./domain/port/has-earned-badge.port";
```

Why abstract class, not interface: interfaces vanish at compile time and cannot be DI tokens; abstract classes give a type and a runtime token in one declaration. `useExisting` (not `useClass`) lets one adapter instance satisfy several ports. The port is named for the fact the consumer wants — never for the provider's storage.

Adapters return facts. They never throw workflow errors — the consuming use case decides whether `false` or `null` is an error.

## 7. Query port + query service

```typescript
// application/query-port/find-progress.query-port.ts
export abstract class FindProgressQuery {
  abstract findByUserAndPath(userId: string, pathId: string): Promise<ProgressProjection | null>;
}
```

The abstract class is the token; the `*QueryService` implementation may hit the ORM directly. Query services return data, `null`, or `[]` — the use case decides whether absence is an error. They exist because a response DTO is usually not a domain entity: it has joins, audit fields, pagination, and cross-module composition no aggregate should carry.

## 8. Error bases and edge translation

```typescript
export abstract class DomainError extends Error {
  abstract readonly code: string;
  abstract readonly category: ErrorCategory;
  constructor(message: string) { super(message); this.name = this.constructor.name; }
}

export abstract class ApplicationError extends Error { /* same shape */ }
```

```typescript
@Catch(DomainError)
export class DomainExceptionFilter implements ExceptionFilter {
  catch(exception: DomainError, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const status = CATEGORY_TO_HTTP_STATUS[exception.category] ?? 500;
    if (status >= 500) this.logger.error(exception);
    response.status(status).json({ error: { code: exception.code, message: exception.message } });
  }
}
```

The `category` — not the throw site — determines the transport status. Nothing in the call path catches domain or application errors; translation happens once, at the edge. Name errors for the exact failed condition: `BadgeImageAssetNotFoundError` tells the caller what to fix; `InvalidBadgeError` does not.

## 9. Test fakes

```typescript
const badgeRepo: BadgeRepositoryPort = { save: vi.fn(), findById: vi.fn() /* … */ };
const uow: UnitOfWork = { run: (work) => work() };
```

The `uow` fake is a one-liner precisely because the unit of work is an abstraction rather than a raw ORM transaction object. No container, no database, milliseconds per test — the architecture made the tests cheap.

## 10. Flow of control, end to end

`POST /badges`, an admin creates a badge with an optional image owned by another module:

1. **Guard** — transport-level authorization runs before anything else.
2. **Validation** — schema parses the body; a bad body becomes a 400 before the use case is reached.
3. **Controller** — one line: hand the validated input to the use case, return the promise.
4. **Cross-module check** — the use case asks the assets module through its published port; it does not know what storage the assets module uses.
5. **Workflow decision** — missing asset → application error thrown by the use case.
6. **Transaction** — the unit of work opens and publishes the ambient transactional manager.
7. **Domain** — `Badge.create()` mints the ID and enforces its invariants; violations throw domain errors.
8. **Persistence** — `save(badge)` through the repository port; the implementation maps and writes; returns `void`.
9. **Response** — the use case returns `{ id }`; the controller serializes 201.
10. **Errors** — nothing in this path catches anything; edge filters map category → status.

Count the files that know the database exists: one — the repository. That is the point.
