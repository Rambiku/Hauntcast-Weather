# Design — M1 · Hazard catalog and recommendations

## Summary

M1 is the static-content module: it loads the 23 hazards and their recommendations into Supabase
via versioned SQL seed files and exposes them through two read-only endpoints. There is no risk
logic and no calls to external data sources. All text in the database is in **English**; language
switching is the frontend's responsibility.

---

## Design decisions

### 1. Versioned SQL seeds, not Django fixtures

The project does not use the Django ORM (`DATABASES = {}`). Content is managed through SQL files
in `supabase/` that are executed once from the Supabase dashboard and tracked in the repository
as the source of truth. This is consistent with M0 and the project structure steering.

### 2. Idempotency strategy

`seed_hazards.sql` uses `INSERT ... SELECT ... WHERE NOT EXISTS (SELECT 1 FROM weather_categories
WHERE code = ...)` because `weather_categories` has no composite unique constraint beyond `code`.

`seed_recommendations.sql` uses the same `WHERE NOT EXISTS` pattern keyed on
`(category_id, title, description)`, since `prevention_recommendations` has only a single-column
primary key (`id uuid`).

`seed_recommendations.sql` (emergency numbers section) uses `ON CONFLICT (country_code, number)
DO UPDATE` to refresh labels, sources and verification dates on repeat runs, matching the primary key
declared in `supabase/schema.sql`. It also removes three previously seeded numbers that were
incorrectly presented as nationwide emergency contacts.

### 3. In-memory cache for the hazard catalog

The catalog does not change while the server is running. `HazardListView` loads it from Supabase
on the first request and stores the result in a module-level variable (`_catalog_cache`).
The sentinel value is `None` (not `[]`), because an empty list from Supabase is a valid — if
unexpected — result that should not be confused with "not yet loaded".

Recommendations are editorial content that can change between deploys, so they are fetched from
Supabase on every request with no aggressive caching at this phase.

### 4. Slug validation before hitting the database

`RecommendationDetailView` validates the `hazard` parameter against `VALID_HAZARD_SLUGS`
(defined in `apps/weather/constants.py`) before making any Supabase call. An unknown slug
returns HTTP 400 immediately, keeping invalid requests out of the database layer.

### 5. HTTP 503 on any Supabase failure

The `handle_supabase_unavailable` decorator in `core/exceptions.py` catches
`SupabaseNotConfiguredError` (missing credentials), `postgrest.exceptions.APIError`
(PostgREST-level error) and `httpx.HTTPError` (network failure), and converts all three to
HTTP 503. This implements the "Never fake calm" principle: the API never returns an empty list
or a silent 200 when data is unavailable.

### 6. Metadata encoded in `description`, not in separate columns

The `weather_categories` schema (from `supabase/schema.sql`) does not have dedicated `group`,
`mvp`, `name_en` or `name_es` columns. The seed stores metadata in existing columns:

- `name` holds the English hazard name.
- `description` holds a structured string: `"group:<group> | mvp:<true|false> | <human text>"`.
- `animation_key` holds the same value as `code` (the slug), for the frontend animation lookup.

The view layer (`_parse_description`, `_split_bilingual_name`) parses these fields at read time
and maps them to the API contract shape. This avoids a schema migration while keeping the
contract stable.

### 7. One row per action in `prevention_recommendations`

The `prevention_recommendations` schema has no array columns (`before[]`, `during[]`, `after[]`).
Each action is stored as a separate row. The `title` column encodes phase, country and source:

```
"Before · PE · INDECI"
"During · US · Ready.gov"
"After  · MX · CENAPRED"
```

`RecommendationRepository.get_by_slug_and_country()` resolves the category UUID, filters by the
country token using `.like("title", "% · <country> · %")`, then groups rows into
`{before, during, after, source}` before returning them to the view.

---

## File structure

```
supabase/
  seed_hazards.sql            23 hazards — columns: code, name, description, animation_key
  seed_recommendations.sql    MVP recommendations × (PE, US, MX) + emergency numbers

apps/weather/
  constants.py                VALID_HAZARD_SLUGS, MVP_HAZARD_SLUGS (frozensets)
  views.py                    HazardListView  →  GET /api/v1/hazards
  urls.py                     path("hazards", HazardListView.as_view())
  repositories.py             HazardCategoryRepository(SupabaseRepository)

apps/recommendations/
  views.py                    RecommendationDetailView  →  GET /api/v1/recommendations
  urls.py                     path("recommendations", RecommendationDetailView.as_view())
  repositories.py             RecommendationRepository(SupabaseRepository)
                              EmergencyNumberRepository(SupabaseRepository)

config/
  urls.py                     includes apps/weather/urls and apps/recommendations/urls

tests/
  test_m1_catalog.py          Endpoint tests with mocked repositories (no live Supabase)
```

---

## Table schemas (from supabase/schema.sql)

### `weather_categories`

| Column         | Type           | Constraint          | Used for                                      |
|----------------|----------------|---------------------|-----------------------------------------------|
| `id`           | `uuid`         | PK (generated)      | FK target from `prevention_recommendations`   |
| `code`         | `varchar(50)`  | UNIQUE NOT NULL     | Canonical hazard slug                         |
| `name`         | `varchar(100)` | NOT NULL            | English hazard name                           |
| `description`  | `text`         |                     | `"group:<g> \| mvp:<bool> \| <human text>"`   |
| `animation_key`| `varchar(100)` |                     | Frontend animation folder (equals `code`)     |
| `created_at`   | `timestamptz`  | DEFAULT now()       |                                               |

> The `icon` column was removed and is not used.

### `prevention_recommendations`

| Column        | Type           | Constraint                             | Used for                                      |
|---------------|----------------|----------------------------------------|-----------------------------------------------|
| `id`          | `uuid`         | PK (generated)                         |                                               |
| `category_id` | `uuid`         | FK → `weather_categories.id` NOT NULL  | Links row to its hazard                       |
| `severity`    | `varchar(20)`  | CHECK IN (INFO, LOW, MODERATE, HIGH, CRITICAL) | Maps to Skull Scale level           |
| `title`       | `varchar(200)` | NOT NULL                               | `"<Phase> · <country_code> · <source>"`       |
| `description` | `text`         | NOT NULL                               | Action text in English                        |
| `created_at`  | `timestamptz`  | DEFAULT now()                          |                                               |

> The `icon` column was removed and is not used.
> There is no `hazard_slug`, `country_code`, `before[]`, `during[]`, `after[]` or `source`
> column. Phase, country and source are all encoded in `title`.

### `emergency_numbers`

| Column        | Type   | Constraint                        | Used for                       |
|---------------|--------|-----------------------------------|--------------------------------|
| `country_code`| `text` | PK (part), CHECK `^[A-Z]{2}$`    | ISO 3166-1 alpha-2             |
| `label`       | `text` | NOT NULL                          | Service name in English        |
| `number`      | `text` | PK (part)                         | Phone number                   |
| `source_name` | `text` | NOT NULL                          | Name of the official source    |
| `source_url`  | `text` | NOT NULL                          | URL of the official source     |
| `verified_at` | `date` | NOT NULL DEFAULT CURRENT_DATE     | Date the number was verified   |

---

## Request flows

### GET /api/v1/hazards

```
Client
  → HazardListView.get()
      → if _catalog_cache is not None: return cached response
      → HazardCategoryRepository.list_all()
          → supabase.table("weather_categories").select("*")
          → on failure: decorator catches exception → HTTP 503
      → parse each row: code → slug, name → name_en,
        description → group + mvp via regex
      → store in _catalog_cache
      → return {"hazards": [...]}  HTTP 200
```

### GET /api/v1/recommendations?hazard=huayco&country=PE

```
Client
  → RecommendationDetailView.get()
      → validate hazard ∈ VALID_HAZARD_SLUGS    → HTTP 400 if not
      → validate country matches [A-Z]{2}        → HTTP 400 if not
      → RecommendationRepository.get_by_slug_and_country(hazard, country)
          → supabase.table("weather_categories")
              .select("id").eq("code", hazard)   → resolve category_id
          → supabase.table("prevention_recommendations")
              .select("title, description")
              .eq("category_id", category_id)
              .like("title", "% · PE · %")        → fetch matching rows
          → group rows by phase prefix → {before, during, after, source}
          → return None if no rows found
          → on failure: decorator catches exception → HTTP 503
      → if None: HTTP 404
      → return {hazard, country, before, during, after, source}  HTTP 200
```

---

## Recommendation content rules

1. **English only.** All action text in the database is in English. The frontend handles
   language display.
2. **Source always cited.** Each group of rows for a (hazard, country) pair shares a source
   encoded in the `title`. If multiple sources are synthesized, the most authoritative one for
   that country is used.
3. **At least two actions per phase.** Each `before`, `during` and `after` group must contain
   at least two concrete, specific actions — no generic advice.
4. **SENAMHI `RECOMENDAC` goes first.** When the SENAMHI provider returns a `RECOMENDAC` field,
   M4 prepends it to the `during` list in the `/api/v1/risk` response. The M1 seed does not
   duplicate that text, but its own actions must be compatible.

### Source reference by hazard and country (MVP selection)

| Hazard              | Peru      | United States | Mexico    |
|---------------------|-----------|---------------|-----------|
| `huayco`            | INDECI    | —             | —         |
| `inundacion`        | INDECI    | Ready.gov     | CENAPRED  |
| `lluvia_intensa`    | INDECI    | Ready.gov     | CENAPRED  |
| `tormenta_electrica`| INDECI    | Ready.gov     | CENAPRED  |
| `helada`            | INDECI    | Ready.gov     | CENAPRED  |
| `ola_calor`         | CENEPRED  | Ready.gov     | CENAPRED  |
| `radiacion_uv`      | CENEPRED  | Ready.gov     | CENAPRED  |
| `viento_fuerte`     | INDECI    | Ready.gov     | CENAPRED  |
| `ciclon_tropical`   | —         | Ready.gov     | CENAPRED  |
| `tornado`           | —         | Ready.gov     | —         |
| `sismo`             | INDECI    | Ready.gov     | CENAPRED  |

---

## Shared constants

```python
# apps/weather/constants.py — single source of truth for hazard slugs

VALID_HAZARD_SLUGS: frozenset[str] = frozenset({
    "lluvia_intensa", "huayco", "inundacion", "tormenta_electrica",
    "granizo", "deslizamiento", "helada", "ola_calor", "radiacion_uv",
    "nevada", "friaje", "viento_fuerte", "ciclon_tropical", "tornado",
    "oleaje", "tsunami", "sismo", "incendio_forestal", "volcan",
    "niebla", "polvo", "calidad_aire", "sequia",
})

MVP_HAZARD_SLUGS: frozenset[str] = frozenset({
    "lluvia_intensa", "huayco", "inundacion", "tormenta_electrica",
    "helada", "ola_calor", "radiacion_uv", "viento_fuerte",
    "ciclon_tropical", "tornado", "sismo",
})
```

Imported by `apps/recommendations/views.py` (validation) and `tests/test_m1_catalog.py`
(assertions).

---

## Test strategy

Tests in `tests/test_m1_catalog.py` mock or patch repository methods; no live Supabase
connection is required.

| Test | What is mocked | What is verified |
|---|---|---|
| `test_hazards_returns_all_23` | `list_all()` → 23 rows | HTTP 200, `len(hazards) == 23` |
| `test_hazards_mvp_count` | `list_all()` → rows with mvp markers | 11 entries with `mvp: true` |
| `test_hazards_parses_group` | `list_all()` → one row with description | `group` field populated correctly |
| `test_recommendations_ok` | `get_by_slug_and_country()` → valid dict | HTTP 200, non-empty lists, source set |
| `test_recommendations_invalid_slug` | repo not called | HTTP 400 |
| `test_recommendations_not_found` | `get_by_slug_and_country()` → `None` | HTTP 404 |
| `test_hazards_supabase_down` | `list_all()` raises network error | HTTP 503 |
| `test_recommendations_supabase_down` | `get_by_slug_and_country()` raises network error | HTTP 503 |
