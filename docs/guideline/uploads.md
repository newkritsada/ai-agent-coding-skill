# Uploads & Object Storage

Foundation for storing user media (PDFs, videos, e-books, images) + worker-produced transcoded renditions. S3-compatible: **MinIO** in dev, **Huawei OBS** in prod.

This is plumbing only — **no DB entity yet**. Tracking uploaded objects (owner, course, status) is a later feature module.

## Two pieces

- **`ObjectStorageService`** (`src/infrastructure/object-storage/`) — `@Global()` thin S3 wrapper, like `CacheService`. Purpose-agnostic. In **both** `AppModule` + `WorkerModule` (worker reads raw uploads, writes renditions).
- **`uploads` module** (`src/modules/uploads/`) — presigned-URL HTTP endpoints. Client uploads **direct to the store**, never through the API.

## Buckets — visibility, not media type

Two buckets, picked by logical `visibility`:

| visibility | bucket env | what | access |
|---|---|---|---|
| `public` | `OBS_BUCKET_PUBLIC` | thumbnails / cover images | anon read, stable URL, CDN-cacheable |
| `private` | `OBS_BUCKET_PRIVATE` | raw uploads, e-books, paid videos, transcoded protected media | presigned GET only |

Split axis = **access semantics**, NOT file type. Thumbnails / cover images -> public. PDF + video -> private. Service resolves visibility -> real bucket; callers never name a bucket.

Public assets presigned = anti-pattern (expiring URLs break CDN cache + SEO). Public bucket -> stable URL via `publicUrl()`.

## `purpose` — the client's only choice

Client sends `purpose`. Server maps `purpose -> { visibility, key prefix, mime allowlist, maxBytes }` via `PURPOSE_POLICY` (in `@ols/shared`, `uploads/schemas.ts`). **Server owns key + bucket.** Client never picks them.

| purpose | visibility | prefix | mime | max |
|---|---|---|---|---|
| `thumbnail` | public | `thumbnails/` | png/jpeg | 20 MB |
| `profile` | public | `profiles/` | png/jpeg | 20 MB |
| `video` | private | `uploads/videos/` | mp4/quicktime | 5 GB |
| `ebook` | private | `ebooks/` | pdf/epub | 200 MB |
| `document` | private | `uploads/documents/` | pdf | 200 MB |

Key = `${prefix}${uuidv7}`. `PURPOSE_POLICY` lives in `@ols/shared` -> web reuses `mime`/`maxBytes` for `<input accept>` + size hint. One source of truth.

## Validation

Zod `superRefine` on shared schema: MIME in allowlist + size <= maxBytes, per purpose. Cross-field. Returns standard 400. No custom errors.

Single presigned PUT can't **hard**-enforce size server-side -> declared `size` advisory now. Hard limit = presigned POST `content-length-range`, later.

## Endpoints

Server owns key/visibility everywhere.

```
POST /uploads                     {purpose, contentType, size}      -> {key, url, expiresAt}
POST /uploads/multipart           {purpose, contentType, size}      -> {key, uploadId}
POST /uploads/multipart/parts     {key, uploadId, partNumbers[]}    -> {parts:[{partNumber,url}], expiresAt}
POST /uploads/multipart/complete  {key, uploadId, parts[]}          -> {key}
POST /uploads/multipart/abort     {key, uploadId}                   -> 204
```

Single PUT for normal files. Multipart for big video. Multipart follow-up calls echo `key`; server re-derives visibility from key prefix (`visibilityForKey`) — never trusts client bucket. Unknown prefix -> `InvalidUploadKeyError` (400).

## `ObjectStorageService` API

```
presignPut({visibility,key,contentType}, expiresIn?)   -> presigned PUT URL (content-type signed)
presignGet({visibility,key}, expiresIn?)               -> presigned GET URL
put({visibility,key,body,contentType})                 -> server-side write (worker renditions)
getStream({visibility,key})                            -> Readable (worker reads raw)
head({visibility,key})                                 -> metadata (confirm upload landed)
delete({visibility,key})
publicUrl(key)                                         -> stable public URL, no signing
createMultipartUpload / presignUploadPart / completeMultipartUpload / abortMultipartUpload
```

Default presign expiry 900s (`defaultExpirySeconds`), overridable.

## Security — must know

- **Content-Type signed.** `presignPut` passes `signableHeaders: new Set(["content-type"])`. Without it AWS SDK signs only `host` -> client could PUT `text/html` to public bucket -> stored XSS over CDN. Mismatch/missing type -> **403**.
- **OBS checksum.** `S3Client` built with `requestChecksumCalculation: "WHEN_REQUIRED"` + `responseChecksumValidation: "WHEN_REQUIRED"`. AWS SDK v3 (~3.729+) default CRC32 checksums -> OBS rejects.
- **No auth yet.** Endpoints OPEN. `// TODO(auth)` on controller. Anyone calling = write access to buckets incl. public. **Must gate with `@UseGuards` before non-local deploy.** Structured for drop-in guard.

## Public URLs + CDN

`publicUrl(key)` = `joinUrl(OBS_PUBLIC_BASE_URL, key)`. `OBS_PUBLIC_BASE_URL` **required**, used verbatim:

- dev: `http://localhost:9000/ols-public` (MinIO)
- prod no CDN: OBS public bucket endpoint
- prod + CDN: CDN domain (origin = public bucket)

Add CDN later = env change only, no code. Public objects get `Cache-Control: public, max-age=31536000, immutable` (server-side `put`/`createMultipartUpload`). Safe forever — UUIDv7 keys immutable per upload, never invalidate CDN. Presigned single PUT can't set Cache-Control (client owns headers) -> apply at CDN layer in prod.

## Env (`OBS_*` -> `OBJECT_STORAGE_ENV.*`)

```
OBS_ENDPOINT OBS_REGION OBS_ACCESS_KEY_ID OBS_SECRET_ACCESS_KEY
OBS_BUCKET_PRIVATE OBS_BUCKET_PUBLIC OBS_FORCE_PATH_STYLE OBS_PUBLIC_BASE_URL
```

## Local dev

`docker compose up minio createbuckets` -> MinIO :9000 (API), :9001 (console). `createbuckets` makes both buckets + sets anon download on public. Creds `minioadmin`/`minioadmin`.

**Presigned-URL caveat (all-in-docker):** set `OBS_ENDPOINT=http://minio:9000` for server-side ops and `OBS_PRESIGN_ENDPOINT=http://localhost:9000` so presigned PUT/GET URLs are browser-reachable (`docker-compose.dev.yml` does this for `api`). Host-run API can omit `OBS_PRESIGN_ENDPOINT` (defaults to `OBS_ENDPOINT`).

## Add a purpose

1. Add to `PurposeSchema` enum + `PURPOSE_POLICY` in `packages/shared/src/uploads/schemas.ts`. Set visibility/prefix/mime/maxBytes.
2. Rebuild shared: `pnpm --filter @ols/shared build`.
3. Done — endpoints + validation pick it up. No new use-case unless new flow.

## Tests

Unit: use-cases (mock `ObjectStorageService`) + `upload-policy`. `ObjectStorageService` = thin I/O wrapper, not unit-tested (like `CacheService`). Don't unit-test Zod schemas — validation lib's job. Tests reading runtime config need `vitest.config.ts` `test.env` (CI has no `.env`).

## Follow-ups (not built)

- Auth guard on `/uploads`
- Bucket lifecycle rule: auto-abort incomplete multipart uploads
- Hard max-size via presigned POST `content-length-range`
- Media-metadata entity + transcoding module
- Verify OBS checksum behavior against real OBS
