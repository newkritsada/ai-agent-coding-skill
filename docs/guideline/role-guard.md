# Role Guard (API)

Role-based route authorization. `@Roles(...)` declares which platform roles may
call a route; `RolesGuard` enforces it from the session.

## Auth vs authorization

| Layer | Tool | Failure |
|---|---|---|
| Authentication | Global `NativeAuthGuard` (session cookie) | **401** |
| Authorization | `@Roles` + `RolesGuard` | **403** |

- Session identity: `request.session.user` (`id`, `role`)
- Roles: `UserRole` from `@ols/shared`; twin-role groups via `RoleGroup`

Route posture:

- Public route: `@AllowAnonymous()`
- Any authenticated user: no decorator
- Specific roles only: `@Roles(...)`

## Files

| File | Role |
|---|---|
| `src/shared/decorators/roles.decorator.ts` | `@Roles(...roles)` — metadata + guard |
| `src/shared/guards/roles.guard.ts` | Session role vs required roles (throws **403**) |
| `src/shared/auth/roles.metadata.ts` | Metadata key + `RequiredRoles` type |
| `packages/shared/src/auth/role.ts` | `RoleGroup` + `isCreator`/`isAdmin` helpers |

`RolesGuard` is a provider in `AppModule`.

## Protect a route

```typescript
import { RoleGroup, UserRole } from "@ols/shared";
import { Roles } from "@/shared/decorators/roles.decorator";

@Get()
@Roles(UserRole.ADMIN_USER)          // exact role
list() { ... }

@Post()
@Roles(...RoleGroup.CREATORS)        // CREATOR + NDLP_CREATOR
create() { ... }
```

Prefer `RoleGroup` over listing twin roles (`CREATOR`/`NDLP_CREATOR`) by hand —
NDLP provenance must not change what a role may do.

## Actor context in handlers

`@UserContext()` provides `{ id, role }`, validated per request. Use it instead
of reading `session.user` or casting roles.

## Instance checks

The route guard is coarse (role only). Ownership and state rules ("is the
creator of this media") belong in use cases and domain objects, not the guard.

## Adding a role-protected route

1. Decorate the handler with `@Roles(...)` (use `RoleGroup` where applicable)
2. Cover the rejection in the route's e2e feature when the 403 is a primary
   business rule
3. `pnpm --filter @ols/shared build && pnpm --filter @ols/api typecheck`
