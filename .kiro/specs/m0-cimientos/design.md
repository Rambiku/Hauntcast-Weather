# Design Document — M0 · Cimientos (Foundations)

## Overview

M0 establishes the shared infrastructure that lets Gabriel (backend) and Luciana (frontend) work in
parallel. It has no user-facing features: its output is a runnable, checkable Django backend with a
clean dependency manifest, correct settings, the shared data model for hazard alerts, the API
contract document, and the Kiro usage log.

The module resolves three concrete defects in the current repository—settings carrying unused Django
apps, `CorsMiddleware` placed last in `MIDDLEWARE`, and the Supabase client crashing on import when
credentials are absent—while also creating the files that do not yet exist.

---

## Architecture

All changes are confined to the backend layer. No new endpoints are added; the existing
`GET /api/v1/locations/test-connection/` endpoint is updated as a side-effect of fixing the lazy
Supabase client.

```
┌───────────────────────────────────────────────────────────┐
│  HTTP request                                             │
│       │                                                   │
│       ▼                                                   │
│  corsheaders.middleware.CorsMiddleware  ← must be FIRST   │
│  django.middleware.security.SecurityMiddleware            │
│  django.middleware.common.CommonMiddleware                │
│  django.middleware.csrf.CsrfViewMiddleware                │
│  django.middleware.clickjacking.XFrameOptionsMiddleware   │
│       │                                                   │
│       ▼                                                   │
│  View (apps/*/views.py)                                   │
│       │                                                   │
│       ▼                                                   │
│  core.supabase_client.get_client()  ← lazy singleton      │
│       │                                                   │
│       ├── credentials present → returns supabase.Client  │
│       └── credentials absent  → raises                   │
│                                    SupabaseNotConfigured  │
│                                    Error → HTTP 503       │
└───────────────────────────────────────────────────────────┘
```

The `integrations/weather_providers/base.py` module sits outside the HTTP path; it defines the
shared protocol and data model consumed by M3 (providers) and M4 (alert engine).

---

## Components and Interfaces

### 1. `requirements.txt`

Exact content of the file at repository root. Versions are pinned with `==` for reproducibility.

```
Django==6.1
djangorestframework==3.18.0
django-cors-headers==4.9.0
supabase==2.34.1
python-dotenv==1.1.0
httpx==0.28.1
pytest==9.2.0
pytest-django==4.14.0
hypothesis==6.170.0
```

**Rationale for each version:**
- `Django==6.1`: the version the project targets (released August 2026).
- `djangorestframework==3.18.0`: first DRF release with declared Django 6.1 support.
- `django-cors-headers==4.9.0`: current stable release, compatible with Django 6.x.
- `supabase==2.34.1`: current stable supabase-py release (November 2026).
- `python-dotenv==1.1.0`: current stable release.
- `httpx==0.28.1`: used by M3 providers for outbound HTTP; pinned to avoid API churn before the
  stable 1.0 release.
- `pytest==9.2.0`: current stable pytest release (October 2026).
- `pytest-django==4.14.0`: the first release with explicit Django 6.1 support (August 2026).
- `hypothesis==6.170.0`: current stable Hypothesis release (October 2026).

---

### 2. `.env.example`

Exact content:

```
# Copy this file to .env and fill in real values.
# Never commit .env to version control.

SECRET_KEY=your-secret-key-here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-service-role-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
```

---

### 3. `LICENSE`

Standard MIT license text with copyright year 2026 and team name "Hauntcast Weather (Gabriel &
Luciana)".

```
MIT License

Copyright (c) 2026 Hauntcast Weather (Gabriel & Luciana)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### 4 & 5. `config/settings.py` — final design

The file replaces the current one completely. Key decisions:

**`INSTALLED_APPS`** — removes the five unused Django contrib apps:

```python
INSTALLED_APPS = [
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "apps.users",
    "apps.locations",
    "apps.weather",
    "apps.alerts",
    "apps.recommendations",
    "apps.notifications",
]
```

**`MIDDLEWARE`** — `CorsMiddleware` is the first entry per django-cors-headers docs, then the
remaining standard middleware, minus the three auth/session/messages entries:

```python
MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
```

**`TEMPLATES`** — removes the two context processors that require `django.contrib.auth` and
`django.contrib.messages`:

```python
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
            ],
        },
    },
]
```

**`REST_FRAMEWORK`** — disables authentication and permission globally (APIs are public by default
in Phase 1) and prevents DRF from attempting to load `AnonymousUser`:

```python
REST_FRAMEWORK = {
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],
    "DEFAULT_AUTHENTICATION_CLASSES": [],
    "DEFAULT_PERMISSION_CLASSES": [],
    "UNAUTHENTICATED_USER": None,
}
```

**`DEBUG` and `ALLOWED_HOSTS`** — read from environment with safe defaults:

```python
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

DEBUG = os.getenv("DEBUG", "False").lower() in ("1", "true", "yes")
_allowed = os.getenv("ALLOWED_HOSTS", "")
ALLOWED_HOSTS = [h.strip() for h in _allowed.split(",") if h.strip()] or [
    "localhost",
    "127.0.0.1",
]
SECRET_KEY = os.getenv("SECRET_KEY", "")
```

The default for `DEBUG` is `False` (safe for production). The default for `ALLOWED_HOSTS` falls back
to `["localhost", "127.0.0.1"]` when the env var is absent or empty.

**`DATABASES`** — remains `{}` (no Django ORM).

**`AUTH_PASSWORD_VALIDATORS`** — removed (requires `django.contrib.auth`).

---

### 6. `config/urls.py` — final design

```python
from django.urls import path, include

urlpatterns = [
    path("api/v1/locations/", include("apps.locations.urls")),
]
```

Removes the `admin/` route and the `from django.contrib import admin` import. Future apps add their
routes here under `api/v1/<app>/`.

---

### 7. `core/supabase_client.py` — lazy singleton

**Problem:** the current module raises `ValueError` at import time when env vars are absent, which
breaks `manage.py check` and the development server startup.

**Solution:** module-level `_client: Client | None = None` initialized to `None`. A `get_client()`
function creates the client on first call and caches it. If credentials are missing, it raises a
custom `SupabaseNotConfiguredError`.

```python
# core/supabase_client.py
from __future__ import annotations

import os
from pathlib import Path
from typing import TYPE_CHECKING

from dotenv import load_dotenv

if TYPE_CHECKING:
    from supabase import Client

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

_client: "Client | None" = None


class SupabaseNotConfiguredError(RuntimeError):
    """Raised when SUPABASE_URL or SUPABASE_KEY are not set."""


def get_client() -> "Client":
    """Return the shared Supabase client, creating it on first call.

    Raises:
        SupabaseNotConfiguredError: if SUPABASE_URL or SUPABASE_KEY are absent.
    """
    global _client
    if _client is None:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        if not url or not key:
            raise SupabaseNotConfiguredError(
                "SUPABASE_URL and SUPABASE_KEY must be set in the environment."
            )
        from supabase import create_client  # deferred import keeps startup fast
        _client = create_client(url, key)
    return _client
```

**`core/supabase_repository.py`** — updated to call `get_client()` inside the `.table` property
instead of importing `supabase` at module level:

```python
# core/supabase_repository.py
from __future__ import annotations

from typing import Any

from core.supabase_client import get_client


class SupabaseRepository:
    """SDK-backed CRUD scaffold for a single public table."""

    table_name: str

    @property
    def table(self):
        return get_client().table(self.table_name)

    # list(), get(), create(), update(), delete() remain unchanged
```

**`apps/locations/views.py`** — updated to call `get_client()` and handle
`SupabaseNotConfiguredError`:

```python
# apps/locations/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from core.supabase_client import get_client, SupabaseNotConfiguredError


class SupabaseConnectionView(APIView):

    def get(self, request):
        try:
            client = get_client()
            result = client.table("countries").select("*").limit(5).execute()
            return Response({
                "success": True,
                "message": "Conexión con Supabase exitosa",
                "data": result.data,
            })
        except SupabaseNotConfiguredError:
            return Response(
                {"error": "Data source unavailable",
                 "detail": "Supabase credentials not configured"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except Exception as e:
            return Response(
                {"success": False, "error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
```

#### 7a. `core/exceptions.py` — 503 helper

To avoid repeating the `SupabaseNotConfiguredError → 503` pattern in every view, `core/` exposes a
small helper:

```python
# core/exceptions.py
from __future__ import annotations

from functools import wraps
from typing import Callable

from rest_framework import status
from rest_framework.response import Response

from core.supabase_client import SupabaseNotConfiguredError


def handle_supabase_unavailable(view_func: Callable) -> Callable:
    """Decorator that converts SupabaseNotConfiguredError into HTTP 503."""

    @wraps(view_func)
    def wrapper(*args, **kwargs):
        try:
            return view_func(*args, **kwargs)
        except SupabaseNotConfiguredError:
            return Response(
                {
                    "error": "Data source unavailable",
                    "detail": "Supabase credentials not configured",
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

    return wrapper
```

Usage in a view method: `@handle_supabase_unavailable` applied to `get`, `post`, etc.

Alternatively, a DRF `APIView` mixin can override `handle_exception` to intercept the error. Both
patterns are acceptable; the decorator is simpler for the Phase 1 view count.

---

### 8. `integrations/weather_providers/base.py` — complete code

```python
# integrations/weather_providers/base.py
from __future__ import annotations

import dataclasses
from typing import Protocol


@dataclasses.dataclass
class HazardAlert:
    """One normalized hazard alert returned by any weather provider.

    ``level`` is an integer on the Skull Scale (0 = Calm, 4 = Extreme).
    ``kind`` is either "official" (issued by a national weather service)
    or "estimated" (computed from forecast data with thresholds).
    ``starts_at`` and ``ends_at`` are UTC ISO 8601 timestamps.
    """

    id: str
    hazard: str                      # one of the 23 slugs in hazards.md
    level: int                       # 0–4 Skull Scale
    kind: str                        # "official" | "estimated"
    source: str                      # e.g. "senamhi", "nws", "open_meteo"
    title: str
    description: str
    official_recommendation: str | None   # SENAMHI RECOMENDAC or NWS instruction
    area_name: str | None
    starts_at: str                   # UTC ISO 8601
    ends_at: str | None              # UTC ISO 8601 or None
    source_url: str | None


@dataclasses.dataclass
class ProviderResult:
    """Outcome of a single provider fetch.

    When ``ok`` is True the fetch succeeded; ``alerts`` may be empty (meaning
    the source was reachable but found no active hazards for that point) and
    ``error`` is None.

    When ``ok`` is False the fetch failed; ``alerts`` is always an empty list
    and ``error`` contains a human-readable description of the failure.
    The alert engine uses ``ok`` and ``error`` to populate the
    ``sources_status`` array in the /api/v1/risk response, so the frontend can
    distinguish "no hazards" from "source unavailable" and comply with the
    "Never fake calm" principle.
    """

    source: str             # provider name, matches HazardAlert.source
    ok: bool
    alerts: list[HazardAlert]
    error: str | None       # None when ok=True; descriptive message when ok=False


class WeatherProvider(Protocol):
    """Protocol that every data-source adapter must satisfy.

    Implementations must be registered in ``services/alert_engine.py``.
    """

    name: str  # e.g. "senamhi", "nws", "open_meteo"

    def covers(self, country_code: str) -> bool:
        """Return True if this provider has data for the given ISO-3166-1 alpha-2 country code."""
        ...

    def fetch_alerts(self, lat: float, lon: float) -> ProviderResult:
        """Return alerts for the given coordinates.

        This method MUST NOT raise any exception to the caller.
        All errors (network timeouts, malformed responses, missing credentials,
        etc.) must be caught internally and returned as a ProviderResult with
        ``ok=False``, ``alerts=[]``, and a descriptive ``error`` string.

        A ProviderResult with ``ok=True`` and an empty ``alerts`` list is a
        valid, successful result that means the source was reachable and found
        no active alerts for that location.
        """
        ...
```

---

### 9. `docs/api-contract.md` — document structure

The API contract document has the following sections. Full content is written as a separate task.

```
# Hauntcast Weather — API Contract

> This document may only be modified through a Pull Request approved by both teammates.

## Versioning

All endpoints are served under `/api/v1/`.
JSON keys are in snake_case. Timestamps are UTC ISO 8601 (e.g. `2026-11-24T18:00:00Z`).

## Endpoints

### GET /api/v1/risk
### GET /api/v1/locations/resolve
### GET /api/v1/locations/search
### GET /api/v1/hazards
### GET /api/v1/recommendations

## GET /api/v1/risk — full response schema

[Complete JSON example with all fields, field types, constraints]

Field notes:
- `overall_level`: integer 0–4 (Skull Scale maximum of active alerts)
- `kind`: "official" | "estimated"
- `level`: integer 0–4

## Shared types

### HazardAlert

[Python dataclass signature as defined in base.py]

### ProviderResult

[Python dataclass signature as defined in base.py]

### WeatherProvider (Protocol)

[Python protocol signature as defined in base.py]

## Hazard catalog

| Slug | Hazard | Group | MVP |
|------|--------|-------|-----|

### Group: water
lluvia_intensa, huayco, inundacion, tormenta_electrica, granizo, deslizamiento

### Group: cold_heat
helada, ola_calor, radiacion_uv, nevada, friaje

### Group: wind_sea
viento_fuerte, ciclon_tropical, tornado, oleaje, tsunami

### Group: earth_fire_air
sismo, incendio_forestal, volcan, niebla, polvo, calidad_aire, sequia
```

---

### 10. `docs/bitacora-kiro.md` — initial entry

```markdown
# Bitácora de uso de Kiro — Hauntcast Weather

## 24 de noviembre de 2026

**Spec M0 creado con workflow requirements-first**

- Se establecieron cinco steering files: `product.md`, `tech.md`, `structure.md`,
  `hazards.md`, `workflow.md`. Estos archivos alimentan cada request de Kiro con el
  contexto completo del proyecto sin necesidad de repetirlo en cada prompt.
- Se creó `requirements.md` para M0 con 11 requisitos usando el workflow
  requirements-first de Kiro. Las preguntas de clarificación de Kiro ayudaron a
  descubrir el requisito de lazy initialization (Req 11), que no estaba en el backlog
  inicial.
- Se creó `design.md` para M0: Kiro investigó versiones compatibles de paquetes para
  Django 6.1, diseñó el patrón de lazy singleton para el cliente Supabase, y definió
  el código completo de `base.py` con el protocolo `WeatherProvider` y los dataclasses
  `HazardAlert` y `ProviderResult`.
- `integrations/weather_providers/base.py` fue scaffoldeado por Kiro a partir del
  diseño; contiene el protocolo y los modelos de datos compartidos por todos los
  módulos futuros.
```

---

## Data Models

### `HazardAlert` fields

| Field | Type | Constraint |
|-------|------|-----------|
| `id` | `str` | unique per alert |
| `hazard` | `str` | one of 23 slugs from `hazards.md` |
| `level` | `int` | 0 ≤ level ≤ 4 |
| `kind` | `str` | `"official"` or `"estimated"` |
| `source` | `str` | provider name |
| `title` | `str` | — |
| `description` | `str` | — |
| `official_recommendation` | `str \| None` | present only on official alerts that carry it |
| `area_name` | `str \| None` | — |
| `starts_at` | `str` | UTC ISO 8601 |
| `ends_at` | `str \| None` | UTC ISO 8601 or None |
| `source_url` | `str \| None` | — |

### `ProviderResult` fields

| Field | Type | Constraint |
|-------|------|-----------|
| `source` | `str` | matches `HazardAlert.source` |
| `ok` | `bool` | — |
| `alerts` | `list[HazardAlert]` | always `[]` when `ok=False` |
| `error` | `str \| None` | always `None` when `ok=True` |

### Invariants

- `ok=True` → `error is None` and `alerts` may be any list (including empty).
- `ok=False` → `alerts == []` and `error` is a non-empty string.
- `0 ≤ alert.level ≤ 4` for every `HazardAlert`.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a
system — essentially, a formal statement about what the system should do. Properties serve as the
bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Successful ProviderResult has no error

*For any* `ProviderResult` constructed with `ok=True`, the `error` field must be `None`.

**Validates: Requirements 9.2**

### Property 2: Failed ProviderResult has empty alerts

*For any* `ProviderResult` constructed with `ok=False`, the `alerts` field must be an empty list.

**Validates: Requirements 9.2**

### Property 3: HazardAlert level is in range

*For any* `HazardAlert`, the `level` field must be an integer in the closed range [0, 4].

**Validates: Requirements 9.1**

---

## Error Handling

### `SupabaseNotConfiguredError`

Raised by `core.supabase_client.get_client()` when `SUPABASE_URL` or `SUPABASE_KEY` are absent.
Views catch this exception using the `handle_supabase_unavailable` decorator from
`core.exceptions` and return:

```json
HTTP 503 Service Unavailable
{
  "error": "Data source unavailable",
  "detail": "Supabase credentials not configured"
}
```

### `ProviderResult` failure path

When a provider's `fetch_alerts` encounters any error (timeout, malformed JSON, HTTP non-2xx,
etc.), it returns `ProviderResult(ok=False, alerts=[], error="<description>")`. The alert engine
(M4) surfaces this in `sources_status` and falls back to Open-Meteo. It never raises to the view
layer.

### `manage.py check` without credentials

After the lazy singleton refactor, importing `core.supabase_client` at startup does not call
`get_client()`, so no `SupabaseNotConfiguredError` is raised. The check command completes with
zero errors.

---

## Testing Strategy

### Unit tests (example-based)

These tests cover the M0 deliverables directly. They live in `tests/test_m0_foundations.py`.

**Supabase lazy init:**
- Importing `core.supabase_client` without env vars does not raise any exception.
- Calling `get_client()` without env vars raises `SupabaseNotConfiguredError`.
- Calling `get_client()` twice with credentials returns the same object (singleton).

**`SupabaseRepository.table` property:**
- Calling `.table` without env vars raises `SupabaseNotConfiguredError` (not an `AttributeError`).

**View 503 behavior:**
- `GET /api/v1/locations/test-connection/` without credentials returns HTTP 503 with the expected
  JSON body.

**Settings:**
- `CorsMiddleware` is `MIDDLEWARE[0]`.
- `django.contrib.admin` is not in `INSTALLED_APPS`.
- `DEBUG` defaults to `False` when the env var is absent.

### Property-based tests (Hypothesis)

These tests run with a minimum of 100 iterations each. They live in
`tests/test_m0_properties.py` and are tagged for traceability.

Each `@given` block is annotated with:
```
# Feature: m0-cimientos, Property N: <property text>
```

**Property 1 — Successful ProviderResult has no error:**
Generate `ProviderResult` instances with `ok=True` and arbitrary `source`, `alerts`, and verify
`error is None`.

**Property 2 — Failed ProviderResult has empty alerts:**
Generate `ProviderResult` instances with `ok=False` and arbitrary `source` and `error`, and verify
`alerts == []`.

**Property 3 — HazardAlert level is in range:**
Generate `HazardAlert` instances with arbitrary valid field values (Hypothesis `st.builds`) and
verify `0 <= alert.level <= 4`. Since `HazardAlert` is a plain dataclass, the strategy generates
instances with an `int` level field constrained to `st.integers(min_value=0, max_value=4)`.

> **Note:** Properties 1 and 2 test the data model contracts directly on `ProviderResult`;
> they do not require a running server or database.

### `pytest.ini` / `conftest.py`

A `pytest.ini` at the repository root configures `DJANGO_SETTINGS_MODULE`:

```ini
[pytest]
DJANGO_SETTINGS_MODULE = config.settings
python_files = tests/test_*.py
```
