# Implementation Plan: M0 · Cimientos (Foundations)

## Overview

Establishes the shared backend infrastructure: dependency manifest, environment template, license,
corrected Django settings, lazy Supabase client, shared data models, API contract, usage log, and
test suite. No user-facing features; the done condition is `python manage.py check` with zero errors.

## Tasks

- [x] 1. Create `requirements.txt`
  - Write the file at the repository root with these exact pinned versions:
    `Django==6.1`, `djangorestframework==3.18.0`, `django-cors-headers==4.9.0`,
    `supabase==2.34.1`, `python-dotenv==1.1.0`, `httpx==0.28.1`,
    `pytest==9.2.0`, `pytest-django==4.14.0`, `hypothesis==6.170.0`.
  - Use `==` for every package; no ranges, no extras.
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Create `.env.example`
  - Write the file at the repository root with placeholder entries for
    `SECRET_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`, `DEBUG=True`, and
    `ALLOWED_HOSTS=localhost,127.0.0.1`.
  - All values must be clearly fake; no real credentials.
  - Add a comment at the top: `# Copy this file to .env and fill in real values. Never commit .env.`
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Create `LICENSE`
  - Write the standard MIT License text with copyright year 2026 and team name
    "Hauntcast Weather (Gabriel & Luciana)".
  - _Requirements: 3.1_

- [x] 4. Rewrite `core/supabase_client.py` — lazy singleton
  - Add `from __future__ import annotations` and `TYPE_CHECKING` guard for the `Client` type hint.
  - Remove the module-level `create_client()` call that currently raises on import.
  - Define `class SupabaseNotConfiguredError(RuntimeError)` with a clear docstring.
  - Add a module-level `_client: Client | None = None`.
  - Implement `get_client() -> Client`: on first call read `SUPABASE_URL` and `SUPABASE_KEY`
    from env, raise `SupabaseNotConfiguredError` if either is absent, otherwise call
    `create_client()` (deferred import), cache in `_client`, and return it; on subsequent calls
    return the cached instance.
  - The module must import without raising even when env vars are absent.
  - _Requirements: 11.1, 11.2_

- [x] 5. Update `core/supabase_repository.py` — use `get_client()`
  - Replace `from core.supabase_client import supabase` with
    `from core.supabase_client import get_client`.
  - Change the `.table` property body from `supabase.table(self.table_name)` to
    `get_client().table(self.table_name)`.
  - Leave `list()`, `get()`, `create()`, `update()`, `delete()` unchanged.
  - _Requirements: 11.1, 11.2_

- [x] 6. Create `core/exceptions.py` — 503 decorator
  - Add `from __future__ import annotations` and import `functools.wraps`, `Callable`,
    `rest_framework.status`, `rest_framework.response.Response`, and
    `core.supabase_client.SupabaseNotConfiguredError`.
  - Implement `handle_supabase_unavailable(view_func: Callable) -> Callable`: a decorator that
    wraps a view method and catches `SupabaseNotConfiguredError`, returning
    `Response({"error": "Data source unavailable", "detail": "Supabase credentials not configured"}, status=503)`.
  - _Requirements: 11.3_

- [x] 7. Rewrite `config/settings.py` — fix all settings defects
  - Set `INSTALLED_APPS` to exactly:
    `["django.contrib.staticfiles", "rest_framework", "corsheaders",
    "apps.users", "apps.locations", "apps.weather", "apps.alerts",
    "apps.recommendations", "apps.notifications"]`.
    Remove `admin`, `auth`, `contenttypes`, `sessions`, `messages`.
  - Set `MIDDLEWARE` with `"corsheaders.middleware.CorsMiddleware"` as the first entry, followed by
    `SecurityMiddleware`, `CommonMiddleware`, `CsrfViewMiddleware`, `XFrameOptionsMiddleware`.
    Remove `SessionMiddleware`, `AuthenticationMiddleware`, `MessageMiddleware`.
  - Set `TEMPLATES[0]["OPTIONS"]["context_processors"]` to only
    `["django.template.context_processors.request"]`.
    Remove the `auth` and `messages` context processors.
  - Set `REST_FRAMEWORK` to include `DEFAULT_RENDERER_CLASSES`, empty
    `DEFAULT_AUTHENTICATION_CLASSES`, empty `DEFAULT_PERMISSION_CLASSES`,
    and `"UNAUTHENTICATED_USER": None`.
  - Replace hardcoded `DEBUG = True` and `ALLOWED_HOSTS` with env-driven reads:
    `DEBUG = os.getenv("DEBUG", "False").lower() in ("1", "true", "yes")` and
    `ALLOWED_HOSTS = [h.strip() for h in os.getenv("ALLOWED_HOSTS","").split(",") if h.strip()] or ["localhost","127.0.0.1"]`.
  - Remove `AUTH_PASSWORD_VALIDATORS` (requires `django.contrib.auth`).
  - Remove the `MAILERS` block (not a standard Django setting).
  - Keep `DATABASES = {}`, `TIME_ZONE = "UTC"`, `USE_TZ = True`, `CORS_ALLOWED_ORIGINS`.
  - _Requirements: 4.1, 4.2, 4.4, 4.6, 4.7, 5.1, 5.2, 6.1, 6.2_

- [x] 8. Rewrite `config/urls.py` — routes under `/api/v1/`
  - Remove `from django.contrib import admin` and the `admin/` path.
  - Set `urlpatterns` to a single entry: `path("api/v1/locations/", include("apps.locations.urls"))`.
  - Add a comment: `# Future apps add their routes here under api/v1/<app>/`.
  - _Requirements: 4.3, 7.1, 7.2_

- [x] 9. Update `apps/locations/views.py` — handle `SupabaseNotConfiguredError`
  - Replace `from core.supabase_client import supabase` with
    `from core.supabase_client import get_client, SupabaseNotConfiguredError`.
  - Import `handle_supabase_unavailable` from `core.exceptions` and apply it to the `get` method.
  - In the `get` method, call `get_client()` to obtain the client before querying.
  - The `SupabaseNotConfiguredError` path is handled by the decorator and returns HTTP 503 with
    `{"error": "Data source unavailable", "detail": "Supabase credentials not configured"}`.
  - _Requirements: 4.8, 11.3_

- [x] 10. Rewrite `integrations/weather_providers/base.py` — data models and protocol
  - Add `from __future__ import annotations`, `import dataclasses`, `from typing import Protocol`.
  - Define `@dataclasses.dataclass class HazardAlert` with these 11 fields (in order):
    `id: str`, `hazard: str`, `level: int`, `kind: str`, `source: str`, `title: str`,
    `description: str`, `official_recommendation: str | None`, `area_name: str | None`,
    `starts_at: str`, `ends_at: str | None`, `source_url: str | None`.
  - Define `@dataclasses.dataclass class ProviderResult` with 4 fields:
    `source: str`, `ok: bool`, `alerts: list[HazardAlert]`, `error: str | None`.
  - Define `class WeatherProvider(Protocol)` with:
    - `name: str` class attribute
    - `covers(self, country_code: str) -> bool`
    - `fetch_alerts(self, lat: float, lon: float) -> ProviderResult` with a docstring
      stating the no-raise contract and explaining the difference between
      `ok=True, alerts=[]` (reachable, no hazards) and `ok=False` (failure).
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 11. Create `docs/api-contract.md`
  - Create the `docs/` directory if it doesn't exist.
  - Document all five endpoints under `/api/v1/`: `GET /risk`, `GET /locations/resolve`,
    `GET /locations/search`, `GET /hazards`, `GET /recommendations`.
  - Include the complete JSON response schema for `GET /api/v1/risk` with all fields shown,
    types noted, `kind` constrained to `"official" | "estimated"`, and `level`/`overall_level`
    noted as integers 0–4.
  - State that all timestamps are UTC ISO 8601.
  - Include the Python signatures of `HazardAlert`, `ProviderResult`, and `WeatherProvider`
    with `fetch_alerts` shown as returning `ProviderResult`.
  - List all 23 hazard slugs from `hazards.md` in a table grouped by category.
  - Add the note at the top: `> This document may only be modified through a Pull Request approved by both teammates.`
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [x] 12. Create `docs/bitacora-kiro.md`
  - Write an initial entry dated 24 de noviembre de 2026.
  - Record that the M0 spec was created with Kiro (requirements-first workflow), that the five
    steering files (`product.md`, `tech.md`, `structure.md`, `hazards.md`, `workflow.md`) were
    established, and that `base.py` was scaffolded by Kiro.
  - _Requirements: 10.1, 10.2_

- [x] 13. Create `pytest.ini` and `tests/conftest.py`
  - Write `pytest.ini` at the repository root with:
    ```ini
    [pytest]
    DJANGO_SETTINGS_MODULE = config.settings
    python_files = tests/test_*.py
    ```
  - Create an empty `tests/__init__.py` to make `tests/` a package.
  - Write `tests/conftest.py` with any shared fixtures needed by unit and property tests
    (e.g., a fixture that temporarily sets env vars for Supabase credentials using
    `monkeypatch.setenv`).
  - _Requirements: 4.5, 11.4_

- [x] 14. Checkpoint — Verify settings correctness before writing tests
  - Ensure all tests pass, ask the user if questions arise.

- [x] 15. Create `tests/test_m0_foundations.py` — unit tests
  - [x] 15.1 Test: importing `core.supabase_client` without env vars does not raise
    - Use `importlib.reload` or a fresh import in a subprocess-safe way; assert no exception is
      thrown when `SUPABASE_URL` and `SUPABASE_KEY` are absent.
    - _Requirements: 11.1_
  - [ ]* 15.2 Test: `get_client()` without env vars raises `SupabaseNotConfiguredError`
    - Temporarily clear `SUPABASE_URL` and `SUPABASE_KEY` with `monkeypatch.delenv`
      (use `raising=False`); also reset `_client` to `None`; call `get_client()` and assert
      `SupabaseNotConfiguredError` is raised.
    - _Requirements: 11.2_
  - [ ]* 15.3 Test: `get_client()` called twice returns the same object (singleton)
    - Set fake credentials with `monkeypatch.setenv`; patch `supabase.create_client` to return a
      mock; reset `_client` to `None`; call `get_client()` twice; assert both calls return the
      same object and `create_client` was called exactly once.
    - _Requirements: 11.2_
  - [ ]* 15.4 Test: `GET /api/v1/locations/test-connection/` without credentials returns 503
    - Use DRF's `APIClient`; ensure env vars are absent; call the endpoint; assert
      `response.status_code == 503` and `response.json()["error"] == "Data source unavailable"`.
    - _Requirements: 11.3_
  - [ ]* 15.5 Test: `CorsMiddleware` is `MIDDLEWARE[0]`
    - Import `MIDDLEWARE` from `config.settings`; assert
      `MIDDLEWARE[0] == "corsheaders.middleware.CorsMiddleware"`.
    - _Requirements: 5.1_
  - [ ]* 15.6 Test: `django.contrib.admin` is not in `INSTALLED_APPS`
    - Import `INSTALLED_APPS` from `config.settings`; assert
      `"django.contrib.admin" not in INSTALLED_APPS`.
    - _Requirements: 4.1_
  - [ ]* 15.7 Test: `DEBUG` defaults to `False` when env var is absent
    - Reload `config.settings` with `SUPABASE_URL`, `SUPABASE_KEY`, and `DEBUG` removed from env
      using `monkeypatch.delenv`; assert `settings.DEBUG is False`.
    - _Requirements: 6.1_

- [ ] 16. Create `tests/test_m0_properties.py` — Hypothesis property tests
  - [ ]* 16.1 Property 1: `ProviderResult(ok=True)` → `error is None`
    - Annotate with `# Feature: m0-cimientos, Property 1: Successful ProviderResult has no error`.
    - Use `@given(st.text(), st.lists(st.builds(HazardAlert, ...)))` to generate `ProviderResult`
      instances with `ok=True` and arbitrary `source` and `alerts`; assert `result.error is None`.
    - _Requirements: 9.2_
  - [ ]* 16.2 Property 2: `ProviderResult(ok=False)` → `alerts == []`
    - Annotate with `# Feature: m0-cimientos, Property 2: Failed ProviderResult has empty alerts`.
    - Generate `ProviderResult` instances with `ok=False`, arbitrary `source` and non-empty `error`;
      assert `result.alerts == []`.
    - _Requirements: 9.2_
  - [ ]* 16.3 Property 3: `HazardAlert.level` is always in [0, 4]
    - Annotate with `# Feature: m0-cimientos, Property 3: HazardAlert level is in range`.
    - Use `st.builds(HazardAlert, level=st.integers(min_value=0, max_value=4), ...)` to generate
      valid `HazardAlert` instances; assert `0 <= alert.level <= 4`.
    - _Requirements: 9.1_

- [x] 17. Final checkpoint — Verify foundation is complete
  - Run `python manage.py check` (must complete with zero errors and zero warnings).
  - Start the server manually with `python manage.py runserver` to confirm it starts without errors.
  - Confirm that `GET /api/v1/locations/test-connection/` returns HTTP 503 when `.env` is absent
    or credentials are empty — this is the expected, correct behavior.
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP.
- Each task references specific requirements for traceability.
- On Windows use `python`, not `python3`.
- Never use the Django ORM, models, or migrations; `DATABASES = {}` is intentional.
- Never commit `.env` or any file containing real credentials.
- After completing task 4, reset `core.supabase_client._client = None` in tests that need a fresh
  singleton; use `monkeypatch` to avoid cross-test state pollution.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1", "2", "3", "4"] },
    { "id": 1, "tasks": ["5", "6"] },
    { "id": 2, "tasks": ["7", "10"] },
    { "id": 3, "tasks": ["8", "9"] },
    { "id": 4, "tasks": ["11", "12"] },
    { "id": 5, "tasks": ["13"] },
    { "id": 6, "tasks": ["14"] },
    { "id": 7, "tasks": ["15.1"] },
    { "id": 8, "tasks": ["15.2", "15.3", "15.4", "15.5", "15.6", "15.7"] },
    { "id": 9, "tasks": ["16.1", "16.2", "16.3"] },
    { "id": 10, "tasks": ["17"] }
  ]
}
```
