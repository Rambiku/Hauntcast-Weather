# Tasks — M1 · Hazard catalog and recommendations

## Task summary

| # | Task | Owner | Depends on |
|---|------|-------|------------|
| 1 | Hazard slug constants | Luciana | — |
| 2 | Data repositories | Luciana | — |
| 3 | Hazard catalog seed | Luciana | — |
| 4 | Recommendations and emergency numbers seed | Luciana | 3 |
| 5 | GET /api/v1/hazards endpoint | Luciana | 1, 2 |
| 6 | GET /api/v1/recommendations endpoint | Luciana | 1, 2 |
| 7 | Register routes in config/urls.py | Luciana | 5, 6 |
| 8 | Module tests | Luciana | 1, 2, 5, 6 |

---

## Task 1 · Hazard slug constants

Create `apps/weather/constants.py` with two `frozenset` constants as the single source of
truth for hazard slugs.

**Done when:**
- [x] `VALID_HAZARD_SLUGS` contains exactly 23 slugs matching `hazards.md`.
- [x] `MVP_HAZARD_SLUGS` contains exactly 11 slugs.
- [x] `from apps.weather.constants import VALID_HAZARD_SLUGS` imports without errors.

---

## Task 2 · Data repositories

Implement the repositories that encapsulate all Supabase access for M1.

**`apps/weather/repositories.py` — `HazardCategoryRepository`:**
- [x] Extends `SupabaseRepository`.
- [x] `list_all() -> list[dict]` — queries `weather_categories`, returns all rows.
- [x] `get_by_slug(slug: str) -> dict | None` — filters by `code = slug`.

**`apps/recommendations/repositories.py` — `RecommendationRepository`:**
- [x] Extends `SupabaseRepository`.
- [x] `get_by_slug_and_country(hazard_slug, country_code) -> dict | None` — resolves
  `category_id` from `weather_categories.code`, fetches rows filtered by country token
  in `title` (`.like("title", "% · <country> · %")`), groups by phase prefix
  (`Before` / `During` / `After`) and returns `{before, during, after, source}` or `None`.
- [x] `list_by_hazard(hazard_slug) -> list[dict]` — returns all raw rows for a hazard.

**`apps/recommendations/repositories.py` — `EmergencyNumberRepository`:**
- [x] Extends `SupabaseRepository`.
- [x] `list_by_country(country_code) -> list[dict]` — returns `label` and `number` columns.

**Done when:**
- [x] All repositories have correct type hints.
- [x] No view or service calls `supabase.table()` directly.
- [x] `python manage.py check` passes with zero errors.

---

## Task 3 · Hazard catalog seed

Create `supabase/seed_hazards.sql` with the 23 hazards.

**Done when:**
- [x] The file inserts all 23 hazards using columns `code`, `name`, `description`,
  `animation_key` — matching `supabase/schema.sql`. No `icon`, `slug`, `name_es`,
  `name_en`, `group` or `mvp` columns are used.
- [x] `name` is the English hazard name.
- [x] `description` follows the `"group:<g> | mvp:<bool> | <text>"` format for all 23 rows.
- [x] `animation_key` equals `code` for every row.
- [x] The 11 MVP hazards have `mvp:true` in `description`.
- [x] The seed is idempotent via `WHERE NOT EXISTS (SELECT 1 FROM weather_categories WHERE code = ...)`.
- [x] The file can be executed on the Supabase schema without errors.

---

## Task 4 · Recommendations and emergency numbers seed

Create `supabase/seed_recommendations.sql`.

**Done when:**
- [x] Rows exist for each applicable (MVP hazard × country) combination using columns
  `category_id`, `severity`, `title`, `description` — matching `supabase/schema.sql`.
  No `icon`, `hazard_slug`, `country_code`, `before[]`, `during[]`, `after[]` or `source`
  columns are used.
- [x] `category_id` is resolved via subquery: `(SELECT id FROM weather_categories WHERE code = '<slug>')`.
- [x] `title` follows the `"<Phase> · <country_code> · <source>"` format exactly, with phase
  as `Before`, `During` or `After`.
- [x] `description` contains the action text in English.
- [x] Each phase has at least two rows per (hazard, country) combination.
- [x] The seed is idempotent via `WHERE NOT EXISTS (... AND title = ... AND description = ...)`.
- [x] Emergency numbers use all six columns from `supabase/schema.sql`:
  `country_code`, `label`, `number`, `source_name`, `source_url`, `verified_at`.
- [x] Emergency number insert uses `ON CONFLICT (country_code, number) DO NOTHING`.

---

## Task 5 · GET /api/v1/hazards endpoint

**Done when:**
- [x] `apps/weather/views.py` contains `HazardListView` as a DRF `APIView`.
- [x] The view calls `HazardCategoryRepository.list_all()` and caches the result in a
  module-level `_catalog_cache` variable (sentinel `None`).
- [x] `_build_hazard_payload()` reads `code` → `slug`, `name` → `name_en`, and parses
  `description` with `_parse_description()` to extract `group` and `mvp`.
- [x] `apps/weather/urls.py` defines `path("hazards", HazardListView.as_view(), name="hazard-list")`.
- [x] Response shape: `{"hazards": [{slug, name_en, group, mvp}, ...]}`.
- [x] Returns HTTP 503 `{"error": "Data source unavailable"}` on any Supabase failure.
- [x] Returns HTTP 200 from the development server when the seed is loaded.

---

## Task 6 · GET /api/v1/recommendations endpoint

**Done when:**
- [x] `apps/recommendations/views.py` contains `RecommendationDetailView` as a DRF `APIView`.
- [x] Validates `hazard` against `VALID_HAZARD_SLUGS`; returns HTTP 400 on failure.
- [x] Validates `country` against `[A-Z]{2}`; returns HTTP 400 on failure.
- [x] Returns HTTP 400 for missing parameters.
- [x] Returns HTTP 404 when the repository returns `None`.
- [x] Returns HTTP 503 on any Supabase failure.
- [x] Response shape: `{hazard, country, before, during, after, source}`.
- [x] `apps/recommendations/urls.py` defines
  `path("recommendations", RecommendationDetailView.as_view(), name="recommendation-detail")`.

---

## Task 7 · Register routes in config/urls.py

**Done when:**
- [x] `config/urls.py` includes `apps.weather.urls` under `api/v1/`.
- [x] `config/urls.py` includes `apps.recommendations.urls` under `api/v1/`.
- [x] `GET /api/v1/hazards` does not return 404 for a missing route.
- [x] `GET /api/v1/recommendations?hazard=huayco&country=PE` does not return 404 for a
  missing route.
- [x] `python manage.py check` passes with zero errors.

---

## Task 8 · Module tests

Create `tests/test_m1_catalog.py`.

**Done when:**
- [ ] `pytest tests/test_m1_catalog.py` completes without import or configuration errors.
- [ ] Test: `GET /api/v1/hazards` → HTTP 200, `len(data["hazards"]) == 23`.
- [ ] Test: 11 hazards have `mvp: true` in the response.
- [ ] Test: `group` field is populated correctly from the `description` column.
- [ ] Test: `GET /api/v1/recommendations?hazard=huayco&country=PE` → HTTP 200, all three
  lists non-empty, `source` set.
- [ ] Test: invalid slug → HTTP 400.
- [ ] Test: `hazard=huayco&country=ZZ` → HTTP 404.
- [ ] Test: Supabase down on `/api/v1/hazards` → HTTP 503.
- [ ] Test: Supabase down on `/api/v1/recommendations` → HTTP 503.
- [ ] All tests use mocks; no live Supabase connection required.

---

## Definition of Done for M1

M1 is complete when:

1. `GET /api/v1/hazards` returns all 23 hazards with `slug`, `name_en`, `group` and `mvp`.
2. `GET /api/v1/recommendations?hazard=<mvp_slug>&country=<PE|US|MX>` returns `before`,
   `during` and `after` lists with the source cited.
3. Both endpoints return HTTP 503 (never a silent 200) when Supabase is unavailable.
4. `pytest tests/test_m1_catalog.py` passes.
5. `seed_hazards.sql` and `seed_recommendations.sql` are in the repository and idempotent.
6. `python manage.py check` passes with zero errors.
