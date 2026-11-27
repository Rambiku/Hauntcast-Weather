# Hauntcast Weather — API Contract

> **This document may only be modified through a Pull Request approved by both teammates.**

All endpoints are served under `/api/v1/`.
JSON keys are in `snake_case`. Timestamps are UTC ISO 8601 (e.g. `2026-11-24T18:00:00Z`).

**Language policy:** all text returned by the API is in **English**. Language switching
(English / Spanish) is handled entirely by the frontend.

---

## Endpoints

| Method | Path | Description | Module |
|--------|------|-------------|--------|
| GET | `/api/v1/risk` | Overall risk level, active alerts and recommendations for a location | M4 |
| GET | `/api/v1/locations/resolve` | Resolve coordinates to country, region and city | M2 |
| GET | `/api/v1/locations/search` | Search cities by name | M2 |
| GET | `/api/v1/hazards` | Hazard catalog (slug, English name, group, mvp flag) | M1 |
| GET | `/api/v1/recommendations` | What to do before, during and after for a hazard | M1 |

---

## GET /api/v1/risk

**Query parameters:** `lat` (float), `lon` (float)

**Response schema:**

```json
{
  "location": {
    "lat": -16.409,
    "lon": -71.537,
    "country_code": "PE",
    "region": "Arequipa",
    "city": "Arequipa"
  },
  "overall_level": 3,
  "updated_at": "2026-11-21T14:00:00Z",
  "sources_status": [
    { "source": "senamhi", "ok": true,  "error": null },
    { "source": "open_meteo", "ok": true, "error": null }
  ],
  "alerts": [
    {
      "id": "senamhi-quebrada-12345",
      "hazard": "huayco",
      "level": 3,
      "kind": "official",
      "source": "senamhi",
      "title": "Debris flow warning",
      "description": "Heavy rain forecast is likely to activate ravines...",
      "official_recommendation": "Stay alert and follow official information...",
      "area_name": "Arequipa / Arequipa / Cayma",
      "starts_at": "2026-11-21T12:00:00Z",
      "ends_at": "2026-11-22T12:00:00Z",
      "source_url": "https://www.senamhi.gob.pe/"
    }
  ],
  "recommendations": {
    "huayco": {
      "before": ["Identify safe evacuation routes.", "..."],
      "during": ["Move away from ravines immediately.", "..."],
      "after":  ["Do not return until authorities confirm it is safe.", "..."],
      "source": "INDECI"
    }
  },
  "emergency_numbers": [
    { "label": "Fire Department (Bomberos)", "number": "116" }
  ]
}
```

**Field notes:**

| Field | Type | Constraint |
|-------|------|-----------|
| `overall_level` | `int` | 0–4; maximum of all active alert levels (Skull Scale) |
| `kind` | `str` | `"official"` or `"estimated"` only |
| `level` | `int` | 0–4 (Skull Scale) |
| `sources_status[].ok` | `bool` | `false` means the source failed; never hide this as level 0 |
| All `*_at` fields | `str` | UTC ISO 8601 — frontend converts to local time |

---

## GET /api/v1/locations/resolve

**Query parameters:** `lat` (float), `lon` (float)

**Response schema:**

```json
{
  "lat": -16.409,
  "lon": -71.537,
  "country_code": "PE",
  "region": "Arequipa",
  "city": "Arequipa"
}
```

---

## GET /api/v1/locations/search

**Query parameters:** `q` (string)

**Response schema:**

```json
{
  "results": [
    {
      "name": "Arequipa",
      "region": "Arequipa",
      "country_code": "PE",
      "lat": -16.409,
      "lon": -71.537
    }
  ]
}
```

---

## GET /api/v1/hazards

**Response schema:**

```json
{
  "hazards": [
    {
      "slug": "huayco",
      "name_en": "Debris flows",
      "group": "water",
      "mvp": true
    }
  ]
}
```

**Field notes:**

| Field | Type | Description |
|-------|------|-------------|
| `slug` | `str` | Canonical identifier — matches `weather_categories.code` in the database and the frontend animation folder name |
| `name_en` | `str` | English hazard name — read from `weather_categories.name` |
| `group` | `str` | One of `water`, `cold_heat`, `wind_sea`, `earth_fire_air` — parsed from `weather_categories.description` |
| `mvp` | `bool` | `true` for the 11 hazards that must work for the demo — parsed from `weather_categories.description` |

The response always contains all 23 hazards and is cached in memory for the lifetime of the
server process (the catalog does not change between deploys).

---

## GET /api/v1/recommendations

**Query parameters:** `hazard` (slug), `country` (ISO 3166-1 alpha-2)

**Response schema:**

```json
{
  "hazard": "huayco",
  "country": "PE",
  "before": ["Identify safe evacuation routes.", "..."],
  "during": ["Move away from ravines immediately.", "..."],
  "after":  ["Do not return until authorities confirm it is safe.", "..."],
  "source": "INDECI"
}
```

**Error responses:**

| Status | Body | Condition |
|--------|------|-----------|
| 400 | `{"error": "Missing required parameter: hazard"}` | `hazard` param absent |
| 400 | `{"error": "Missing required parameter: country"}` | `country` param absent |
| 400 | `{"error": "Invalid hazard slug"}` | `hazard` not in the 23 canonical slugs |
| 400 | `{"error": "Invalid country code"}` | `country` not matching `[A-Z]{2}` |
| 404 | `{"error": "No recommendations found", "hazard": "...", "country": "..."}` | No data for this combination |
| 503 | `{"error": "Data source unavailable", "detail": "..."}` | Supabase unreachable |

**Implementation note:** recommendations are stored as individual rows in
`prevention_recommendations`. The `title` column encodes phase, country and source as
`"Before · PE · INDECI"`. The repository resolves the category UUID from
`weather_categories.code`, filters by country token and groups rows into the
`before` / `during` / `after` lists returned here.

---

## Shared Types

### HazardAlert

```python
@dataclasses.dataclass
class HazardAlert:
    id: str                            # unique alert identifier
    hazard: str                        # one of the 23 slugs listed below
    level: int                         # 0–4 Skull Scale
    kind: str                          # "official" | "estimated"
    source: str                        # e.g. "senamhi", "nws", "open_meteo"
    title: str
    description: str
    official_recommendation: str | None
    area_name: str | None
    starts_at: str                     # UTC ISO 8601
    ends_at: str | None
    source_url: str | None
```

### ProviderResult

```python
@dataclasses.dataclass
class ProviderResult:
    source: str              # provider name, matches HazardAlert.source
    ok: bool                 # True = fetch succeeded; False = fetch failed
    alerts: list[HazardAlert]  # always [] when ok=False
    error: str | None        # None when ok=True; error description when ok=False
```

### WeatherProvider (Protocol)

```python
class WeatherProvider(Protocol):
    name: str

    def covers(self, country_code: str) -> bool: ...

    def fetch_alerts(self, lat: float, lon: float) -> ProviderResult:
        """MUST NOT raise. On failure return ProviderResult(ok=False, alerts=[], error=...)."""
        ...
```

---

## Hazard Catalog

All 23 slugs are fixed. Changes require a PR approved by both teammates.
`name_en` is the value stored in `weather_categories.name` (English only).
`group` and `mvp` are encoded in `weather_categories.description`.

### Group: water

| Slug | name_en | MVP |
|------|---------|-----|
| `lluvia_intensa` | Heavy rain | ✅ |
| `huayco` | Debris flows | ✅ |
| `inundacion` | Floods | ✅ |
| `tormenta_electrica` | Thunderstorms | ✅ |
| `granizo` | Hail | |
| `deslizamiento` | Landslides | |

### Group: cold_heat

| Slug | name_en | MVP |
|------|---------|-----|
| `helada` | Frost | ✅ |
| `ola_calor` | Heat wave | ✅ |
| `radiacion_uv` | Extreme UV radiation | ✅ |
| `nevada` | Snow and blizzards | |
| `friaje` | Cold surge (Amazon) | |

### Group: wind_sea

| Slug | name_en | MVP |
|------|---------|-----|
| `viento_fuerte` | Strong winds | ✅ |
| `ciclon_tropical` | Tropical cyclone | ✅ |
| `tornado` | Tornado | ✅ |
| `oleaje` | Abnormal waves | |
| `tsunami` | Tsunami | |

### Group: earth_fire_air

| Slug | name_en | MVP |
|------|---------|-----|
| `sismo` | Earthquake | ✅ |
| `incendio_forestal` | Wildfire | |
| `volcan` | Volcanic activity | |
| `niebla` | Dense fog | |
| `polvo` | Dust storm | |
| `calidad_aire` | Poor air quality | |
| `sequia` | Drought | |

---

## Skull Scale

| Level | Name | Color |
|-------|------|-------|
| 0 | Calm | Purple |
| 1 | Watchful | Green |
| 2 | Caution | Yellow |
| 3 | Danger | Orange |
| 4 | Extreme | Red |

- `overall_level` is the **maximum** level of all active alerts. It is 0 only when all sources
  responded and found no active hazards.
- Estimated alerts (`kind: "estimated"`) are capped at level 3. Level 4 is reserved for
  official alerts.
- Unknown or malformed source data maps to level 2 — it never lowers the risk.
