# Cadastra

Cadastral mapping, boundary validation and land-rights registry for Ghana.

## Phase 1 — Core Engine (`backend/`)

FastAPI + PostgreSQL/PostGIS + PyProj.

```bash
docker compose up -d --build          # API on :8000, Postgres on :5433
open http://localhost:8000/docs       # interactive API docs
docker compose run --rm -e DATABASE_URL=postgresql://cadastra:cadastra@db:5432/cadastra api pytest -q
docker compose run --rm api python -m scripts.seed   # DEV ONLY: demo accounts + parcels around East Legon
docker compose run --rm api python -m scripts.create_user admin@example.gh "Full Name" ADMIN   # real accounts
```

### Accounts and roles

| Role | Can |
|---|---|
| SURVEYOR | Submit surveys (field app); view parcels |
| REVIEWER | Approve / reject surveys (portal); view parcels |
| ADMIN | Everything above, plus `GET/POST/PATCH /users` |

- Nobody can review a parcel they submitted; submitter, reviewer and every audit event record who acted.
- `POST /auth/login` returns a 15-minute JWT access token and a 30-day refresh token. Refresh tokens are stored
  hashed and rotate on each `POST /auth/refresh`; replaying a rotated token revokes all of that user's sessions.
- Sign-in is throttled: 10 failures for one email in 15 minutes (cleared by a success), or 100 from one client
  address, return `429` with `Retry-After`. Counts live in Postgres, so they hold across API instances. Behind a
  proxy, set uvicorn's `FORWARDED_ALLOW_IPS` to the proxy addresses so the real client address is used; the
  portal forwards the browser's `X-Forwarded-For`.
- Deactivating a user or changing their password revokes their sessions; role changes apply on the next request.
- `JWT_SECRET` (32+ chars) is required. `docker-compose.yml` has a dev fallback — set a real secret anywhere shared.
- The seed script's dev accounts (`admin@`, `surveyor@`, `reviewer@cadastra.local`, password
  `cadastra-dev-password`) must never exist on a real registry.

Migrations in `backend/migrations/*.sql` are applied automatically on API start.

| Endpoint | Purpose |
|---|---|
| `POST /auth/login` · `/refresh` · `/logout`, `GET /auth/me` | Sessions (everything except `/health` needs a bearer token) |
| `POST /parcels/validate` | Dry-run: topology, geodetic area/perimeter, conflicts |
| `POST /parcels` | Submit a surveyed boundary (PENDING). `client_ref` makes retries idempotent |
| `GET /parcels?bbox=&status=` | GeoJSON FeatureCollection |
| `GET /parcels/{id}` / `/conflicts` / `/events` | Parcel, live overlap check, audit trail |
| `POST /parcels/{id}/approve` · `/reject` | Review; approval refuses any overlap with an APPROVED parcel |
| `GET /parcels/{id}/survey-plan` | Vertex schedule in Ghana National Grid (ft), Ghana Metre Grid, UTM; leg bearings/lengths; area in m²/ha/acres |
| `GET /parcels/extent` | Bounding box of all parcels |
| `GET /tiles/{z}/{x}/{y}.mvt` | Vector tiles for the map (`parcels` layer) |

### Design notes
- Overlap = interiors intersect (`ST_Relate 'T********'`), which catches containment and identical
  boundaries that `ST_Overlaps` misses; shared edges are not conflicts.
- `OVERLAP_TOLERANCE_SQM` (default `0`) ignores slivers below that area.
- `parcel_events` is append-only (enforced by trigger); raw `survey_points` keep per-node accuracy.
- WGS84 → Accra/Leigon datum transforms from the EPSG registry are only accurate to ~5–6 m.

## Phase 2 — Registry Portal (`web/`)

Next.js 16 + MapLibre GL JS + Playwright. Requires the Core Engine running.

```bash
cd web
npm install                 # also copies the MapLibre worker into public/maplibre
npx playwright install chromium
npm run dev -- -p 3100      # http://localhost:3100
```

| Page | Purpose |
|---|---|
| `/` | Registry map (parcel vector tiles coloured by status); click a parcel for its record |
| `/inspector` | Pending surveys queue, red overlap overlay (darker = encroaches an approved parcel), approve/reject with note |
| `/parcels/{id}/certificate` | Printable certificate: map, vertex schedule (Ghana National Grid ft, Ghana Metre Grid, WGS 84), bearings & distances |
| `/api/certificates/{id}` | Same certificate as an A4 PDF (headless Chromium) |

Environment: `CORE_API_URL` (default `http://localhost:8000`), `NEXT_PUBLIC_BASEMAP_TILES` /
`NEXT_PUBLIC_BASEMAP_ATTRIBUTION` (default OpenStreetMap raster), `CERT_RENDER_ORIGIN` (origin Chromium loads the
certificate from; defaults to the request origin).

Notes:
- Sign-in sets httpOnly cookies; page scripts never see tokens. `/core/*` is a server-side proxy that attaches the
  access token and refreshes the session when it expires. Concurrent refreshes are collapsed into one call per
  server process — run a single instance or use sticky sessions.
- Only reviewers and admins see approve/reject, and not on surveys they submitted.
- The default basemap is the public OpenStreetMap tile server, whose usage policy forbids heavy production use;
  switch to a hosted or self-hosted tile provider before launch.

## Phase 3 — Field App (`mobile/`)

Flutter (iOS + Android). Captures boundaries offline and syncs to the Core Engine.

```bash
cd mobile
flutter pub get
dart run build_runner build           # drift database code
flutter test                          # unit + widget tests (no network)
flutter run                           # iOS simulator reaches the API at localhost:8000
flutter run --dart-define=CADASTRA_API_URL=http://192.168.1.20:8000   # physical device
# Release builds: point at the deployed API and a production basemap
flutter build apk --dart-define=CADASTRA_API_URL=https://api.registry.example.gov.gh \
  --dart-define=BASEMAP_URL='https://tiles.example.com/{z}/{x}/{y}.png' --dart-define=BASEMAP_ATTRIBUTION='© …'

# Live end-to-end test (needs the Core Engine running and seeded):
flutter test integration_test/field_survey_test.dart -d <simulator-id>
```

- **Corner mode** averages ~3 s of fixes per corner (inverse-variance weighted); **Walk mode** drops a node every
  N metres and stops itself when you return to the first corner. Fixes worse than the accuracy limit are ignored.
- Area/perimeter are computed on-device with a local ellipsoidal tangent-plane projection, matching PostGIS
  geography results at parcel scale.
- Every node is written to SQLite as it is captured. Finished surveys queue for upload; the survey id is sent as
  `client_ref`, so retries never duplicate a parcel. Network/5xx errors retry automatically (on reconnect, every
  2 minutes, or pull-to-refresh); 4xx refusals (e.g. duplicate title deed) let the surveyor correct and resubmit.
- Surveyors sign in with SURVEYOR (or ADMIN) accounts; tokens are kept in the iOS Keychain / Android Keystore.
  Capture needs no network or live session; if the session ends, surveys stay queued and the app asks the surveyor
  to sign in again. Surveys belong to the account that captured them, so shared devices never upload one
  surveyor's work under another's name.
- GPS comes through a `PositionSource` interface; an external RTK receiver can be added as another implementation.
- Debug builds allow plain HTTP to a local API (iOS `NSAllowsLocalNetworking`, Android debug manifest only).

## Continuous integration

`.github/workflows/ci.yml` runs on every push to `main` and every pull request: backend tests against a PostGIS
service container; portal lint, type check and production build; field app analyze and tests, plus a check that the
committed drift code (`db.g.dart`) matches its schema.

## Deployment (`deploy/`)

One host running Docker Compose: Caddy terminates HTTPS (certificates issued and renewed automatically) in front of
the portal and the Core Engine, which share a private network with PostGIS. Nothing but Caddy publishes a port.

```bash
cp deploy/.env.example deploy/.env      # domains, secrets (openssl rand -hex 32), basemap
docker compose -f deploy/docker-compose.yml up -d --build
# First admin account (prompts for a password):
docker compose -f deploy/docker-compose.yml exec api python -m scripts.create_user ops@lands.gov.gh "Ops Admin" ADMIN
# Backup:
docker compose -f deploy/docker-compose.yml exec -T db pg_dump -U cadastra -Fc cadastra > cadastra-$(date +%F).dump
```

- `PORTAL_DOMAIN` serves the registry portal; `API_DOMAIN` serves the Core Engine for the field app. Both DNS
  records must point at the host before first start.
- The portal image is built on Playwright's image for certificate rendering; keep its tag in `web/Dockerfile` equal to
  the pinned `playwright` version in `web/package.json`.
- The basemap is compiled into the portal at build time (`BASEMAP_TILES`); rebuild after changing it. The public
  OpenStreetMap tile servers forbid production use.
- Run a single portal container: refresh-token rotation is de-duplicated per process. Scaling it out needs sticky
  sessions.
- Never run `scripts/seed.py` here.
