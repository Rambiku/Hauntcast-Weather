# Requirements Document

## Introduction

Module M0 · Cimientos (Foundations) is the one-time setup that enables Gabriel (backend) and Luciana
(frontend) to work in parallel without stepping on each other. This spec covers the backend half of M0:
creating the dependency manifest, the environment template, the license, correcting three known
settings defects, establishing the API contract document, defining the shared `WeatherProvider`
protocol and `HazardAlert` data model, and opening the Kiro usage log.

Nothing in this module is user-facing. Its "done" condition is that any team member can clone the
repository, copy `.env.example` to `.env`, fill in real values, run `python manage.py check`, and get
no errors.

## Glossary

- **Backend**: the Django 6.1 + Django REST Framework application in `apps/`, `config/`, `core/`,
  `integrations/` and `services/`.
- **API_Contract**: the document `docs/api-contract.md` that defines every endpoint shape and may
  only change via a PR approved by both teammates.
- **WeatherProvider**: the `typing.Protocol` class in `integrations/weather_providers/base.py` that
  every data-source adapter must satisfy.
- **HazardAlert**: the dataclass defined in `integrations/weather_providers/base.py` that represents
  one normalized hazard alert returned by any provider.
- **ProviderResult**: the dataclass defined in `integrations/weather_providers/base.py` that wraps
  the outcome of a single provider fetch, distinguishing a successful empty result from a failure.
- **Skull_Scale**: the 0–4 integer risk scale used throughout the system (0 = Calm, 4 = Extreme).
- **Settings**: the Django configuration file at `config/settings.py`.
- **CorsMiddleware**: `corsheaders.middleware.CorsMiddleware` from the `django-cors-headers` library.
- **DRF**: Django REST Framework.

---

## Requirements

### Requirement 1: Dependency manifest

**User Story:** As a team member, I want a `requirements.txt` at the project root, so that I can
reproduce the Python environment with a single `pip install -r requirements.txt`.

#### Acceptance Criteria

1. THE Backend SHALL provide a `requirements.txt` file at the repository root that lists at minimum:
   `django`, `djangorestframework`, `django-cors-headers`, `supabase`, `python-dotenv`, `httpx`,
   `pytest`, and `hypothesis`.
2. THE `requirements.txt` SHALL specify exact versions using `==` for all packages, to ensure
   reproducible builds across team members' machines.
3. THE `requirements.txt` SHALL NOT contain real secrets, API keys, or values that must differ between
   environments.
4. WHEN a team member runs `pip install -r requirements.txt` in a clean virtual environment, THE
   Backend SHALL install without dependency conflicts.

---

### Requirement 2: Environment variable template

**User Story:** As a team member, I want a `.env.example` file, so that I know exactly which
environment variables to set before running the backend.

#### Acceptance Criteria

1. THE Backend SHALL provide a `.env.example` file at the repository root containing placeholder
   entries for `SECRET_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`, `DEBUG`, and `ALLOWED_HOSTS`.
2. THE `.env.example` SHALL set `DEBUG=True` as the development default; `SECRET_KEY`, `SUPABASE_URL`,
   and `SUPABASE_KEY` SHALL contain empty or clearly fake placeholder values, never real credentials.
3. THE Backend SHALL NOT commit a `.env` file containing real credentials to the repository.

---

### Requirement 3: MIT license

**User Story:** As a hackathon participant, I want an MIT `LICENSE` file, so that the submission
satisfies the Kiroween 2026 open-source requirement.

#### Acceptance Criteria

1. THE Backend SHALL provide a `LICENSE` file at the repository root containing the MIT License text
   with copyright year 2026 and the team name "Hauntcast Weather (Gabriel & Luciana)".

---

### Requirement 4: Remove unused Django apps and admin route

**User Story:** As a backend developer, I want `config/settings.py` to list only the apps the project
actually uses, so that `python manage.py check` does not fail and no `/admin/` route exists.

#### Acceptance Criteria

1. THE Settings SHALL NOT include `django.contrib.admin`, `django.contrib.auth`,
   `django.contrib.contenttypes`, `django.contrib.sessions`, or `django.contrib.messages`
   in `INSTALLED_APPS`.
2. THE Settings SHALL include `django.contrib.staticfiles`, `rest_framework`, `corsheaders`, and
   all six project apps (`apps.users`, `apps.locations`, `apps.weather`, `apps.alerts`,
   `apps.recommendations`, `apps.notifications`) in `INSTALLED_APPS`.
3. THE `config/urls.py` SHALL NOT define a route for `admin.site.urls`.
4. THE Settings SHALL configure DRF with `DEFAULT_AUTHENTICATION_CLASSES` set to an empty list,
   `DEFAULT_PERMISSION_CLASSES` set to an empty list, and `UNAUTHENTICATED_USER` set to `None`,
   so that unauthenticated requests are accepted at the API layer by default and DRF does not
   attempt to load `AnonymousUser` on each request.
5. WHEN a team member runs `python manage.py check`, THE Backend SHALL complete with zero errors.
6. THE Settings SHALL NOT include `django.contrib.sessions.middleware.SessionMiddleware`,
   `django.contrib.auth.middleware.AuthenticationMiddleware`, or
   `django.contrib.messages.middleware.MessageMiddleware` in `MIDDLEWARE`.
7. THE Settings SHALL NOT include `django.contrib.auth.context_processors.auth` or
   `django.contrib.messages.context_processors.messages` in
   `TEMPLATES[0]['OPTIONS']['context_processors']`.
8. WHEN a client sends `GET /api/v1/locations/test-connection/`, THE Backend SHALL return a response
   without an HTTP 500 error caused by missing authentication middleware.

---

### Requirement 5: CorsMiddleware position

**User Story:** As a backend developer, I want `CorsMiddleware` placed first in `MIDDLEWARE`, so that
CORS headers are set on every response including error responses, as required by django-cors-headers.

#### Acceptance Criteria

1. THE Settings SHALL list `corsheaders.middleware.CorsMiddleware` as the first entry in the
   `MIDDLEWARE` list, before any other middleware including `SecurityMiddleware`.
2. THE Settings SHALL retain `CORS_ALLOWED_ORIGINS` with at minimum `http://localhost:5173`.

---

### Requirement 6: Environment-driven DEBUG and ALLOWED_HOSTS

**User Story:** As a backend developer, I want `DEBUG` and `ALLOWED_HOSTS` read from the environment,
so that the same codebase can run safely in production without code changes.

#### Acceptance Criteria

1. THE Settings SHALL read `DEBUG` from the environment variable `DEBUG`, defaulting to `False` when
   the variable is absent or empty.
2. THE Settings SHALL read `ALLOWED_HOSTS` from the environment variable `ALLOWED_HOSTS` as a
   comma-separated string, defaulting to `["localhost", "127.0.0.1"]` when the variable is absent
   or empty.
3. WHEN `DEBUG` is `False`, THE Settings SHALL NOT expose internal tracebacks to HTTP clients.

---

### Requirement 7: API routes under /api/v1/

**User Story:** As a frontend developer, I want all API endpoints served under `/api/v1/`, so that
the path prefix matches the API contract and mocks.

#### Acceptance Criteria

1. THE `config/urls.py` SHALL include the locations URL configuration under the prefix `api/v1/locations/`.
2. THE `config/urls.py` SHALL NOT define a path `admin/`.
3. WHEN a future app adds an endpoint, THE Backend SHALL include it under `/api/v1/` to match the
   API contract.

---

### Requirement 8: API contract document

**User Story:** As a team member, I want `docs/api-contract.md` to document every endpoint and
response shape, so that Gabriel and Luciana can work on backend and frontend in parallel using the
same interface definition.

#### Acceptance Criteria

1. THE API_Contract SHALL document all five endpoints: `GET /api/v1/risk`, `GET /api/v1/locations/resolve`,
   `GET /api/v1/locations/search`, `GET /api/v1/hazards`, and `GET /api/v1/recommendations`.
2. THE API_Contract SHALL include the complete JSON shape of the `GET /api/v1/risk` response, with all
   fields shown, field types noted, and the `kind` field constrained to `"official"` or `"estimated"`.
3. THE API_Contract SHALL state that `level` and `overall_level` are integers in the range 0–4
   following the Skull Scale.
4. THE API_Contract SHALL state that all timestamps are UTC in ISO 8601 format.
5. THE API_Contract SHALL include the Python signatures of the `WeatherProvider` protocol and the
   `HazardAlert` and `ProviderResult` dataclasses, with `fetch_alerts` shown as returning
   `ProviderResult`, not `list[HazardAlert]`.
6. THE API_Contract SHALL list all 23 hazard slugs from `hazards.md` in the same table format,
   grouped by category.
7. WHEN a team member proposes a change to the API_Contract, THE API_Contract SHALL only be modified
   through a Pull Request approved by both teammates.

---

### Requirement 9: WeatherProvider protocol and HazardAlert model

**User Story:** As a backend developer, I want `integrations/weather_providers/base.py` to define a
shared protocol and data model, so that every provider adapter returns the same structure and the
alert engine can distinguish a successful empty result from a provider failure.

#### Acceptance Criteria

1. THE `base.py` SHALL define `HazardAlert` as a `dataclasses.dataclass` with the following fields
   and types:
   - `id: str` — unique identifier for the alert
   - `hazard: str` — one of the 23 slugs from `hazards.md`
   - `level: int` — integer from 0 to 4 (Skull Scale)
   - `kind: str` — `"official"` or `"estimated"`
   - `source: str` — provider name (e.g. `"senamhi"`, `"nws"`)
   - `title: str`
   - `description: str`
   - `official_recommendation: str | None` — present only on official alerts that carry it
   - `area_name: str | None`
   - `starts_at: str` — UTC ISO 8601 timestamp
   - `ends_at: str | None`
   - `source_url: str | None`
2. THE `base.py` SHALL define `ProviderResult` as a `dataclasses.dataclass` with the following
   fields and types:
   - `source: str` — provider name, matching the `source` field in `HazardAlert`
   - `ok: bool` — `True` if the fetch succeeded, `False` if it failed
   - `alerts: list[HazardAlert]` — the fetched alerts; empty list when `ok` is `False`
   - `error: str | None` — human-readable error message when `ok` is `False`; `None` when `ok` is `True`
3. THE `base.py` SHALL define `WeatherProvider` as a `typing.Protocol` with:
   - `name: str` class attribute
   - `covers(self, country_code: str) -> bool` method
   - `fetch_alerts(self, lat: float, lon: float) -> ProviderResult` method
4. THE `WeatherProvider.fetch_alerts` method SHALL never raise an exception to the caller;
   implementations must catch all errors internally and return a `ProviderResult` with `ok=False`,
   `alerts=[]`, and a descriptive `error` string. A `ProviderResult` with `ok=True` and an empty
   `alerts` list means the source was reachable and found no active alerts for that location.
5. THE `ProviderResult.ok` and `ProviderResult.error` fields SHALL be the data the alert engine
   (M4) uses to populate the `sources_status` array in the `/api/v1/risk` JSON response, so that
   the frontend can distinguish "no hazards" from "source unavailable" and comply with the
   "Never fake calm" principle.

---

### Requirement 10: Kiro usage log

**User Story:** As a team member, I want `docs/bitacora-kiro.md` to record how Kiro was used during
development, so that we have a running log to draw from for the hackathon write-up.

#### Acceptance Criteria

1. THE Backend SHALL create `docs/bitacora-kiro.md` with an initial entry dated 24 de noviembre de
   2026.
2. THE initial entry SHALL record that the M0 spec was created with Kiro (requirements-first
   workflow), that steering files (`product.md`, `tech.md`, `structure.md`, `hazards.md`,
   `workflow.md`) were established, and that `base.py` was scaffolded by Kiro.
3. WHEN a new notable Kiro usage occurs (spec created, hook added, MCP server used, property-based
   test that caught a bug, prompt that made a difference), THE team SHALL append a dated entry to
   `docs/bitacora-kiro.md`.

---

### Requirement 11: Lazy initialization of the Supabase client

**User Story:** As a backend developer, I want the Supabase client to initialize only when first
used, so that `manage.py check` and the development server start successfully even when
`SUPABASE_URL` and `SUPABASE_KEY` are absent from the environment.

#### Acceptance Criteria

1. THE `core/supabase_client.py` SHALL NOT raise `ValueError` or any other exception at import
   time, regardless of whether `SUPABASE_URL` and `SUPABASE_KEY` are set in the environment.
2. THE `core/supabase_client.py` SHALL create the Supabase client the first time it is requested
   (lazy singleton pattern), not when the module is imported.
3. WHEN `SUPABASE_URL` or `SUPABASE_KEY` are absent from the environment and an endpoint attempts
   to use the Supabase client, THE Backend SHALL respond with HTTP 503 and a JSON body
   `{"error": "Data source unavailable", "detail": "Supabase credentials not configured"}`.
4. WHEN a team member runs `python manage.py check` without Supabase credentials in the
   environment, THE check SHALL complete with zero errors.
5. WHEN the development server starts without Supabase credentials in the environment, THE server
   SHALL start correctly; errors related to missing credentials SHALL occur only when an endpoint
   that requires Supabase is actually called.
