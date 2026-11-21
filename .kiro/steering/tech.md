---
inclusion: always
---

# Tech stack and conventions

## Backend

- **Django 6.1 + Django REST Framework + django-cors-headers**, Python with type hints.
- **Data lives in Supabase** (Postgres) and is accessed with `supabase-py` through repository classes that extend
  `SupabaseRepository` in `core/supabase_repository.py` (one per table, inside each app's `repositories.py`).
  Do **not** use the Django ORM, Django models or migrations: `DATABASES` is intentionally empty.
- The database schema is the source of truth in Supabase; its export lives in `supabase/schema.sql`.
  Seed data (hazard catalog, recommendations, emergency numbers) lives in `supabase/seed_*.sql`.
- **Secrets** come from `.env` through python-dotenv: `SECRET_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`.
  Never hardcode or commit secrets. `SUPABASE_KEY` is the server-side key and must never reach the frontend.
- **API** lives under `/api/v1/`. JSON keys in `snake_case`. Timestamps in UTC, ISO 8601.
  The contract is `docs/api-contract.md`; never change a response shape without updating it.
- **Tests** with `pytest`. Use **Hypothesis** (property-based testing) for the risk-scale mapping, the provider
  normalizers and alert merging. Provider tests use saved real responses (fixtures), never live calls.

## Frontend

- **Vite + React** in `frontend/` (dev server at `http://localhost:5173`, already allowed by CORS). TypeScript preferred.
- The frontend only calls **our backend API**. It never calls weather providers directly and never uses the Supabase
  server key. If optional accounts are added (M7), it uses Supabase Auth with the public `anon` key.
- Until the real endpoint exists, use mocks in `frontend/src/mocks/` that follow the API contract exactly.
- **Real-time location:** `navigator.geolocation.watchPosition`. Re-query `/api/v1/risk` only when the user moved more
  than about 1 km or 10 minutes passed. If permission is denied, offer city search.
- Bilingual UI (English and Spanish).
- Keep the risk level in `<RiskBadge level>` and the hazard visual in `<HazardScene hazard level>`
  (Phase 1: simple icon; Phase 2: Skull Scale and animations). Respect `prefers-reduced-motion`.

## External data sources

| Source | Coverage | Endpoint | Kind |
|---|---|---|---|
| SENAMHI via INDECI GeoSINPAD (ArcGIS REST) | Peru | `https://geosinpad.indeci.gob.pe/indeci/rest/services/Ent_Tecnico_Cientificas/SENAMHI/MapServer/{layer}/query` with a point geometry, `inSR=4326`, `spatialRel=esriSpatialRelIntersects`, `f=json` | official |
| NWS | United States | `https://api.weather.gov/alerts/active?point={lat},{lon}` | official |
| SMN (Conagua) | Mexico | `https://smn.conagua.gob.mx/tools/GUI/webservices/?method=1` (daily) or `method=3` (48 h hourly) | estimated |
| Open-Meteo Forecast | Global, fallback | `https://api.open-meteo.com/v1/forecast` | estimated |
| Open-Meteo Flood | Global | `https://flood-api.open-meteo.com/v1/flood` | estimated |
| USGS | Global earthquakes | `https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson` | official |
| Nominatim (OSM) | Reverse geocoding | `https://nominatim.openstreetmap.org/reverse` | — |
| Open-Meteo Geocoding | City search | `https://geocoding-api.open-meteo.com/v1/search` | — |

SENAMHI layers: `2` debris flows (`AvisoActQuebrada24H`), `3` wildfire risk (`AvisoFWI24H`),
`4` river levels (`AvisoHidrologico24H`, point features), `5` heavy rain (`AvisoPP24H`).
Useful fields: `NIVEL`, `DESCRIPCIO`, `RECOMENDAC`, `FECHA`, `NOMBDEP`, `NOMBPROV`, `NOMBDIST`.

### Rules for every provider

- Every HTTP call has a **timeout** (about 10 seconds).
- Send an identifiable **User-Agent** to NWS and Nominatim: `Hauntcast-Weather (github.com/Rambiku/Hauntcast-Weather)`.
  Do not put personal emails in it.
- **Cache** results for 10–15 minutes, keyed by coordinates rounded to 0.05°. Nominatim: at most 1 request per second.
- **SMN** returns the whole country as a gzip-compressed JSON (about 5 MB uncompressed) with lat/lon per municipality:
  download it at most once per hour and pick the nearest municipality.
- Every provider implements the `WeatherProvider` protocol in `integrations/weather_providers/base.py` and returns
  normalized `HazardAlert` objects. A provider **never raises** to the engine: failures are reported in
  `sources_status` and the engine falls back to Open-Meteo.
