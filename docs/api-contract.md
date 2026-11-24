# Hauntcast Weather — API Contract

> **This document may only be modified through a Pull Request approved by both teammates.**

All endpoints are served under `/api/v1/`.
JSON keys are in `snake_case`. Timestamps are UTC ISO 8601 (e.g. `2026-11-24T18:00:00Z`).

---

## Endpoints

| Method | Path | Description | Module |
|--------|------|-------------|--------|
| GET | `/api/v1/risk` | Overall risk level, active alerts and recommendations for a location | M4 |
| GET | `/api/v1/locations/resolve` | Resolve coordinates to country, region and city | M2 |
| GET | `/api/v1/locations/search` | Search cities by name | M2 |
| GET | `/api/v1/hazards` | Hazard catalog (slug, name, category) | M1 |
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
      "title": "Activación de quebradas",
      "description": "Ante el pronóstico de lluvias es probable la activación de quebradas...",
      "official_recommendation": "Estar atentos a la información oficial...",
      "area_name": "Arequipa / Arequipa / Cayma",
      "starts_at": "2026-11-21T12:00:00Z",
      "ends_at": "2026-11-22T12:00:00Z",
      "source_url": "https://www.senamhi.gob.pe/"
    }
  ],
  "recommendations": {
    "huayco": {
      "before": ["..."],
      "during": ["..."],
      "after": ["..."],
      "source": "INDECI"
    }
  },
  "emergency_numbers": [
    { "label": "Bomberos", "number": "116" }
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
      "name_es": "Huaycos y activación de quebradas",
      "name_en": "Debris flows",
      "group": "water",
      "mvp": true
    }
  ]
}
```

---

## GET /api/v1/recommendations

**Query parameters:** `hazard` (slug), `country` (ISO-3166-1 alpha-2)

**Response schema:**

```json
{
  "hazard": "huayco",
  "country": "PE",
  "before": ["Identify safe evacuation routes.", "..."],
  "during": ["Move away from ravines immediately.", "..."],
  "after": ["Do not return until authorities confirm it is safe.", "..."],
  "source": "INDECI"
}
```

---

## Shared Types

### HazardAlert

```python
@dataclasses.dataclass
class HazardAlert:
    id: str                            # unique alert identifier
    hazard: str                        # one of the 23 slugs below
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

### Group: water

| Slug | Hazard (EN) | Hazard (ES) | MVP |
|------|-------------|-------------|-----|
| `lluvia_intensa` | Heavy rain | Lluvias intensas | ✅ |
| `huayco` | Debris flows | Huaycos | ✅ |
| `inundacion` | Floods | Inundaciones | ✅ |
| `tormenta_electrica` | Thunderstorms | Tormentas eléctricas | ✅ |
| `granizo` | Hail | Granizo | |
| `deslizamiento` | Landslides | Deslizamientos | |

### Group: cold_heat

| Slug | Hazard (EN) | Hazard (ES) | MVP |
|------|-------------|-------------|-----|
| `helada` | Frost | Heladas | ✅ |
| `ola_calor` | Heat wave | Olas de calor | ✅ |
| `radiacion_uv` | Extreme UV | Radiación UV extrema | ✅ |
| `nevada` | Snow / blizzard | Nevadas | |
| `friaje` | Cold surge (Amazon) | Friaje | |

### Group: wind_sea

| Slug | Hazard (EN) | Hazard (ES) | MVP |
|------|-------------|-------------|-----|
| `viento_fuerte` | Strong winds | Vientos fuertes | ✅ |
| `ciclon_tropical` | Tropical cyclone | Ciclón tropical | ✅ |
| `tornado` | Tornado | Tornado | ✅ |
| `oleaje` | Abnormal waves | Oleaje anómalo | |
| `tsunami` | Tsunami | Tsunami | |

### Group: earth_fire_air

| Slug | Hazard (EN) | Hazard (ES) | MVP |
|------|-------------|-------------|-----|
| `sismo` | Earthquake | Sismo | ✅ |
| `incendio_forestal` | Wildfire | Incendio forestal | |
| `volcan` | Volcano | Volcán | |
| `niebla` | Dense fog | Niebla | |
| `polvo` | Dust storm | Tormenta de polvo | |
| `calidad_aire` | Poor air quality | Mala calidad del aire | |
| `sequia` | Drought | Sequía | |

---

## Skull Scale

| Level | Name (EN) | Name (ES) | Color |
|-------|-----------|-----------|-------|
| 0 | Calm | Calma | Purple |
| 1 | Watchful | Atento | Green |
| 2 | Caution | Precaución | Yellow |
| 3 | Danger | Peligro | Orange |
| 4 | Extreme | Extremo | Red |

- `overall_level` is the **maximum** level of all active alerts. It is 0 only when all sources responded and found no active hazards.
- Estimated alerts (`kind: "estimated"`) are capped at level 3. Level 4 is reserved for official alerts.
- Unknown or malformed source data maps to level 2 — it never lowers the risk.
