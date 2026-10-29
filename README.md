# Cadastra

Cadastral mapping, boundary validation and land-rights registry for Ghana.

## Phase 1 — Core Engine (`backend/`)

FastAPI + PostgreSQL/PostGIS + PyProj.

```bash
docker compose up -d --build          # API on :8000, Postgres on :5433
open http://localhost:8000/docs       # interactive API docs
docker compose run --rm -e DATABASE_URL=postgresql://cadastra:cadastra@db:5432/cadastra api pytest -q
docker compose run --rm api python -m scripts.seed   # demo parcels around East Legon, Accra
```

Migrations in `backend/migrations/*.sql` are applied automatically on API start.

| Endpoint | Purpose |
|---|---|
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
- The browser reaches the Core Engine via the `/core/*` rewrite, so no CORS configuration is needed.
- The default basemap is the public OpenStreetMap tile server, whose usage policy forbids heavy production use;
  switch to a hosted or self-hosted tile provider before launch.
- There is no authentication yet: anyone who can reach the portal can approve or reject surveys.

## Phase 3 — Field App (`mobile/`)

Flutter (iOS + Android). Captures boundaries offline and syncs to the Core Engine.

```bash
cd mobile
flutter pub get
dart run build_runner build           # drift database code
flutter test                          # unit + widget tests (no network)
flutter run                           # iOS simulator reaches the API at localhost:8000
flutter run --dart-define=CADASTRA_API_URL=http://192.168.1.20:8000   # physical device
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
- GPS comes through a `PositionSource` interface; an external RTK receiver can be added as another implementation.
- Debug builds allow plain HTTP to a local API (iOS `NSAllowsLocalNetworking`, Android debug manifest only).
