# Self-Hosted Supabase — Docker Compose Walkthrough

This directory contains the Docker Compose stack that backs Hatch locally and in self-hosted production.

## Services

| Service | Image | Port | Role |
|---------|-------|------|------|
| `db` | `pgvector/pgvector:pg16` | — | PostgreSQL 16 + pgvector extension |
| `rest` | `postgrest/postgrest:v12` | — | PostgREST — auto-generated REST API |
| `auth` | `supabase/gotrue:v2` | — | GoTrue — JWT auth, email/OAuth |
| `realtime` | `supabase/realtime:v2` | — | Realtime — WebSocket subscriptions |
| `storage` | `supabase/storage-api:v1` | — | Storage — file uploads via S3/MinIO |
| `minio` | `minio/minio:latest` | 9000, 9001 | S3-compatible object store |
| `kong` | `kong:3.6` | **8000** | API gateway — single entry point |

All Supabase client calls go through Kong on **`http://localhost:8000`**.

## Quick start

### 1. Generate secrets

```bash
# PostgreSQL password — use hex, NOT base64.
# Base64 output contains '/' and '=' which break postgres:// connection URLs.
openssl rand -hex 32

# JWT secret — same constraint applies
openssl rand -hex 32
```

Store the JWT secret value, then generate `ANON_KEY` and `SERVICE_ROLE_KEY` from it
using a local Node one-liner (no Supabase CLI login required):

```bash
JWT_SECRET=<your-jwt-secret> node -e "
const secret = process.env.JWT_SECRET;
const now = Math.floor(Date.now() / 1000);
const exp = now + 10 * 365 * 24 * 60 * 60; // 10 years
const b64u = s => Buffer.from(JSON.stringify(s)).toString('base64url');
const sign = (payload) => {
  const h = Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');
  const p = b64u(payload);
  const sig = require('crypto').createHmac('sha256', secret)
    .update(h + '.' + p).digest('base64url');
  return h + '.' + p + '.' + sig;
};
console.log('ANON_KEY=' + sign({role:'anon',iss:'supabase',iat:now,exp}));
console.log('SERVICE_ROLE_KEY=' + sign({role:'service_role',iss:'supabase',iat:now,exp}));
"
```

> **Note:** `npx supabase gen signing-key` and `npx supabase gen keys` both
> require a Supabase cloud account (`supabase login`). They are not usable for
> self-hosted stacks without a cloud token.

### 2. Configure environment

```bash
cp docker/.env.example docker/.env
```

Fill in every value in `.env`:

| Variable | Description |
|----------|-------------|
| `POSTGRES_PASSWORD` | Strong random password for PostgreSQL |
| `JWT_SECRET` | 32-byte random secret from `openssl rand -base64 32` |
| `ANON_KEY` | JWT with `role: anon` signed with `JWT_SECRET` (see step 1) |
| `SERVICE_ROLE_KEY` | JWT with `role: service_role` signed with `JWT_SECRET` (see step 1) |
| `SECRET_KEY_BASE` | 64-byte hex secret for Realtime (Phoenix) — `openssl rand -hex 64` |
| `MINIO_ROOT_USER` | MinIO admin username |
| `MINIO_ROOT_PASSWORD` | MinIO admin password (min 8 chars) |
| `SITE_URL` | App origin, e.g. `http://localhost:3000` |
| `API_EXTERNAL_URL` | Kong URL, e.g. `http://localhost:8000` |

### 3. Boot the stack

```bash
docker compose -f docker/docker-compose.yml up -d
```

Check all services are healthy:

```bash
docker compose -f docker/docker-compose.yml ps
```

Expected output — all services should show `running` or `healthy`:

```
NAME          IMAGE                        STATUS
hatch-db-1    pgvector/pgvector:pg16       running (healthy)
hatch-rest-1  postgrest/postgrest:v12      running
hatch-auth-1  supabase/gotrue:v2           running
hatch-real-1  supabase/realtime:v2         running
hatch-stor-1  supabase/storage-api:v1      running
hatch-minio-1 minio/minio:latest           running
hatch-kong-1  kong:3.6                     running
```

### 4. Verify endpoints

```bash
# Auth health check
curl http://localhost:8000/auth/v1/health

# REST API (public tables)
curl http://localhost:8000/rest/v1/ \
  -H "apikey: <ANON_KEY>"

# Storage health
curl http://localhost:8000/storage/v1/status
```

### 5. Run the Flutter app against the local stack

```bash
cd apps/hatch
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://localhost:8000 \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

## Database migrations

The `supabase/migrations/` directory is mounted into the `db` container at
`/docker-entrypoint-initdb.d`. PostgreSQL runs all `.sql` files in that
directory on first boot (when the data volume is empty).

The initial migration (`20240101000000_init.sql`) creates all 12 tables and
enables Row-Level Security with owner-or-collaborator policies.

To apply a new migration to a running stack:

```bash
docker compose -f docker/docker-compose.yml exec db \
  psql -U postgres -d hatch -f /dev/stdin < supabase/migrations/<new_file>.sql
```

To reset the database entirely (wipes all data):

```bash
docker compose -f docker/docker-compose.yml down -v
docker compose -f docker/docker-compose.yml up -d
```

## Kong API gateway

Kong runs in DB-less (declarative) mode. Its configuration is in
`docker/kong.yml`. Routes:

| Path prefix | Upstream |
|-------------|----------|
| `/rest/v1` | PostgREST (`:3000`) |
| `/auth/v1` | GoTrue (`:9999`) |
| `/realtime/v1` | Realtime (`:4000`) |
| `/storage/v1` | Storage API (`:5000`) |

To reload Kong config after editing `kong.yml`:

```bash
docker compose -f docker/docker-compose.yml restart kong
```

## MinIO (object storage)

The MinIO admin console is available at **`http://localhost:9001`** during
development. Log in with `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`.

The `hatch-storage` bucket is created automatically by the Storage API on
first use. For manual inspection or bucket creation:

```bash
docker compose -f docker/docker-compose.yml exec minio \
  mc alias set local http://localhost:9000 <MINIO_ROOT_USER> <MINIO_ROOT_PASSWORD>
docker compose -f docker/docker-compose.yml exec minio \
  mc ls local/
```

## Troubleshooting

**`db` container exits immediately**
- Check `POSTGRES_PASSWORD` is set in `.env` — the image requires it.

**`auth` container fails with DB connection errors**
- The `auth` service depends on `db` being healthy. Wait for `db` to pass
  its health check (`pg_isready`) before auth starts. Usually resolves on
  its own with `restart: unless-stopped`.

**`kong` fails to start — `/etc/kong/kong.yml not found`**
- Ensure you are running `docker compose` from the repository root (not from
  inside `docker/`), or adjust the volume path accordingly.

**`rest` returns 401 on every request**
- Include the `apikey` header with your `ANON_KEY`. PostgREST requires a JWT
  or the `anon` role to be granted `SELECT` on the requested table.

**Migration did not run**
- The init scripts only run when the data volume is empty. If the `pgdata`
  volume already exists, drop it with `docker compose down -v` and restart.

## Logs

```bash
# All services
docker compose -f docker/docker-compose.yml logs -f

# Specific service
docker compose -f docker/docker-compose.yml logs -f db
docker compose -f docker/docker-compose.yml logs -f auth
docker compose -f docker/docker-compose.yml logs -f kong
```
