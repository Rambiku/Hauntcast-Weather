# Requirements — M1 · Hazard catalog and recommendations

## Introduction

Module M1 loads the static content the rest of the app consumes: the 23 hazards in the catalog
and, for each MVP hazard, the set of recommendations (before, during, after) per country.
This content is stored in Supabase through versioned SQL files in the repository and exposed
through two read-only API endpoints.

All text stored in the database is in **English**. Language switching is handled entirely by
the frontend; the backend serves a single language.

M1 does **not** implement risk logic or call external data sources — that is M3 and M4.
Done condition: `GET /api/v1/hazards` and `GET /api/v1/recommendations` return real data with
cited sources, and the frontend (M5) can consume them without mocks.

**Owner:** Luciana.
**Prerequisite:** M0 complete (Supabase schema exported, `base.py` defined, contract approved).

---

## Glossary

- **Slug**: lowercase, underscore-separated text identifier for a hazard, shared by the database
  (`weather_categories.code`), the backend, the frontend and the animation folder names.
  The 23 slugs are fixed in `hazards.md` and `docs/api-contract.md`. Renaming requires a PR
  approved by both teammates.
- **`code`**: the column in `weather_categories` that holds the slug. It is `UNIQUE NOT NULL`.
- **`group`**: hazard category, encoded in `weather_categories.description` as `group:<value>`.
  Valid values: `water`, `cold_heat`, `wind_sea`, `earth_fire_air`.
- **`mvp`**: boolean flag encoded in `weather_categories.description` as `mvp:true` or
  `mvp:false`. The 11 MVP hazards are the ones that must work for the demo.
- **Recommendation**: the before/during/after actions for a hazard in a specific country,
  stored as individual rows in `prevention_recommendations` and grouped by the view layer.
- **Title convention**: each `prevention_recommendations` row encodes phase, country and source
  in the `title` column as `"<Phase> · <country_code> · <source>"`,
  e.g. `"Before · PE · INDECI"`, `"During · US · Ready.gov"`.
- **Emergency number**: official phone number per country, verified from public sources.
- **`weather_categories`**: Supabase table that stores the hazard catalog.
- **`prevention_recommendations`**: Supabase table that stores recommendations per hazard
  and country, one row per action.
- **`emergency_numbers`**: Supabase table that stores emergency phone numbers per country.
- **`HazardCategoryRepository`**: class in `apps/weather/repositories.py` that accesses
  `weather_categories`.
- **`RecommendationRepository`**: class in `apps/recommendations/repositories.py` that accesses
  `prevention_recommendations`.
- **Skull Scale**: the 0–4 integer risk scale used throughout the app.

---

## Requirements

### Requirement 1: Hazard catalog seed

**User Story:** As a frontend developer, I want the `weather_categories` table to contain the
23 hazards, so I can query any hazard by its slug from day one without depending on the risk
engine.

#### Acceptance criteria

1. THE backend SHALL provide `supabase/seed_hazards.sql` with one `INSERT` row per hazard for
   all 23 hazards defined in `hazards.md` and `docs/api-contract.md`.
2. EACH row SHALL populate the following columns that exist in `supabase/schema.sql`:
   - `code` — the canonical slug (unique identifier).
   - `name` — the hazard name in English.
   - `description` — metadata string in the format `"group:<group> | mvp:<true|false> | <human text>"`.
   - `animation_key` — same value as `code`; matches the frontend animation folder name.
3. THE 11 MVP hazards SHALL have `mvp:true` in their `description` field. They are:
   `lluvia_intensa`, `huayco`, `inundacion`, `tormenta_electrica`, `helada`, `ola_calor`,
   `radiacion_uv`, `viento_fuerte`, `ciclon_tropical`, `tornado`, `sismo`.
4. THE seed SHALL be idempotent: it SHALL use `INSERT ... SELECT ... WHERE NOT EXISTS (SELECT 1
   FROM weather_categories WHERE code = ...)` so it can be re-run without duplicating rows.
5. NO slug SHALL appear more than once; all slugs SHALL match exactly the values in `hazards.md`.

---

### Requirement 2: Recommendations seed

**User Story:** As a user, I want to see what to do before, during and after each MVP hazard,
with the official source cited, so I can take informed action.

#### Acceptance criteria

1. THE backend SHALL provide `supabase/seed_recommendations.sql` with rows in
   `prevention_recommendations` covering each applicable (MVP hazard × country) combination
   for Peru (`PE`), United States (`US`) and Mexico (`MX`). Combinations with no applicable
   official guidance (e.g. `huayco` for US/MX, `tornado` for PE/MX) are intentionally omitted
   and return HTTP 404 from the API.
2. EACH row SHALL populate `category_id` (resolved via subquery on `weather_categories.code`),
   `severity` (one of `INFO`, `LOW`, `MODERATE`, `HIGH`, `CRITICAL`), `title` (following the
   `"<Phase> · <country_code> · <source>"` convention) and `description` (the action text in
   English).
3. THE `title` field SHALL encode the phase as exactly `Before`, `During` or `After`
   (capitalized, no other values).
4. EACH phase SHALL have at least two concrete, verifiable actions stored as separate rows
   (not generic advice like "be careful").
5. The `source` portion of `title` SHALL name a recognized official organization:
   INDECI or CENEPRED for Peru; Ready.gov or FEMA for the US; CENAPRED or Protección Civil
   for Mexico.
6. THE seed SHALL be idempotent via `WHERE NOT EXISTS (SELECT 1 FROM prevention_recommendations
   WHERE category_id = ... AND title = ... AND description = ...)`.
7. ALL action text SHALL be written in English.

---

### Requirement 3: Emergency numbers seed

**User Story:** As a user in a dangerous situation, I want to see my country's emergency numbers,
so I know who to call.

#### Acceptance criteria

1. THE backend SHALL include emergency numbers for Peru, the United States and Mexico in
   `supabase/seed_recommendations.sql` (or in a separate `supabase/seed_emergency_numbers.sql`).
2. EACH country SHALL include at least fire, police and medical emergency numbers.
3. EACH row SHALL populate all six columns defined in `supabase/schema.sql`:
   `country_code`, `label`, `number`, `source_name`, `source_url`, `verified_at`.
4. THE seed SHALL use `ON CONFLICT (country_code, number) DO UPDATE` to refresh the label,
   source and verification date for existing rows, matching the primary key defined in the schema.
5. THE numbers SHALL be verifiable from the cited `source_url`.

---

### Requirement 4: Data access repositories

**User Story:** As a backend developer, I want dedicated repositories for the catalog and
recommendations so that views never call Supabase directly.

#### Acceptance criteria

1. `apps/weather/repositories.py` SHALL contain `HazardCategoryRepository` extending
   `SupabaseRepository` from `core/supabase_repository.py`.
2. `HazardCategoryRepository` SHALL expose:
   - `list_all() -> list[dict]` — returns all rows from `weather_categories`.
   - `get_by_slug(slug: str) -> dict | None` — filters by `code = slug`.
3. `apps/recommendations/repositories.py` SHALL contain `RecommendationRepository` extending
   `SupabaseRepository`.
4. `RecommendationRepository` SHALL expose:
   - `get_by_slug_and_country(hazard_slug: str, country_code: str) -> dict | None` — resolves
     `category_id` from `weather_categories.code`, fetches all matching rows filtered by the
     country token in `title`, groups them into `{before, during, after, source}` and returns
     that dict, or `None` if no rows exist.
   - `list_by_hazard(hazard_slug: str) -> list[dict]` — returns all raw rows for a hazard
     (all countries, all phases); used by M4.
5. `apps/recommendations/repositories.py` SHALL also contain `EmergencyNumberRepository`
   extending `SupabaseRepository` with:
   - `list_by_country(country_code: str) -> list[dict]` — returns `label` and `number` for
     each emergency number in the given country.
6. NO view or service SHALL call `supabase.table()` directly; all queries SHALL go through
   the appropriate repository.

---

### Requirement 5: GET /api/v1/hazards endpoint

**User Story:** As a frontend developer, I want an endpoint that returns the full hazard
catalog so I can display the list and filter by group or MVP flag without extra client logic.

#### Acceptance criteria

1. THE backend SHALL implement `GET /api/v1/hazards` in `apps/weather/views.py` and register
   the route in `config/urls.py` under `/api/v1/`.
2. THE response SHALL be HTTP 200 with the following shape (matches `docs/api-contract.md`):
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
   `slug` is read from `code`; `name_en` from `name`; `group` and `mvp` are parsed from
   `description` using the `group:<value>` and `mvp:<true|false>` markers.
3. THE response SHALL include all 23 hazards when the table is fully seeded.
4. THE endpoint SHALL NOT accept query parameters; it always returns the full catalog.
5. WHEN Supabase is unavailable, THE endpoint SHALL return HTTP 503
   `{"error": "Data source unavailable"}`, never a silent empty list.
6. THE endpoint SHALL cache the catalog in memory after the first successful fetch (module-level
   sentinel variable). Supabase SHALL NOT be called more than once per server process for this
   endpoint.

---

### Requirement 6: GET /api/v1/recommendations endpoint

**User Story:** As a user, I want to see what to do before, during and after a specific hazard
in my country, so I can act safely.

#### Acceptance criteria

1. THE backend SHALL implement `GET /api/v1/recommendations` in
   `apps/recommendations/views.py` and register the route in `config/urls.py` under `/api/v1/`.
2. THE endpoint SHALL accept:
   - `hazard` (required): one of the 23 canonical slugs.
   - `country` (required): ISO 3166-1 alpha-2 code (two uppercase letters).
3. THE response SHALL follow the contract shape exactly:
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
4. WHEN no rows exist for the (hazard, country) combination, THE endpoint SHALL return
   HTTP 404 `{"error": "No recommendations found", "hazard": "...", "country": "..."}`.
5. WHEN `hazard` is not one of the 23 valid slugs, THE endpoint SHALL return
   HTTP 400 `{"error": "Invalid hazard slug"}`.
6. WHEN `country` is not exactly two uppercase letters, THE endpoint SHALL return
   HTTP 400 `{"error": "Invalid country code"}`.
7. WHEN either required parameter is absent, THE endpoint SHALL return
   HTTP 400 `{"error": "Missing required parameter: <name>"}`.
8. WHEN Supabase is unavailable, THE endpoint SHALL return
   HTTP 503 `{"error": "Data source unavailable"}`.

---

### Requirement 7: Routes registered in config/urls.py

**User Story:** As a backend developer, I want M1 routes included in the main router so the
frontend finds them under `/api/v1/`.

#### Acceptance criteria

1. `config/urls.py` SHALL include `apps.weather.urls` under the prefix `api/v1/`.
2. `config/urls.py` SHALL include `apps.recommendations.urls` under the prefix `api/v1/`.
3. `GET /api/v1/hazards` SHALL return HTTP 200 from the development server.
4. `GET /api/v1/recommendations?hazard=huayco&country=PE` SHALL return HTTP 200 (seed loaded)
   or HTTP 503 (Supabase unavailable), never HTTP 404 due to a missing route.

---

### Requirement 8: Module tests

**User Story:** As a team, we want automated tests for M1 to catch regressions before they
break M4 or M5.

#### Acceptance criteria

1. THE module SHALL include tests in `tests/test_m1_catalog.py` covering:
   - `GET /api/v1/hazards` returns 200 and all 23 expected slugs.
   - `GET /api/v1/hazards` has exactly 11 hazards with `mvp: true`.
   - `GET /api/v1/recommendations?hazard=huayco&country=PE` returns 200 with non-empty
     `before`, `during` and `after` lists.
   - An invalid slug returns 400.
   - `hazard=huayco&country=ZZ` returns 404.
   - Supabase down on `/api/v1/hazards` returns 503.
   - Supabase down on `/api/v1/recommendations` returns 503.
2. ALL tests SHALL use `APIRequestFactory` and mock/patch the repository methods; no live
   Supabase connection is required to run them.
3. `pytest tests/test_m1_catalog.py` SHALL complete without import or configuration errors.
