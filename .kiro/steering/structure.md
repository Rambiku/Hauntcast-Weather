---
inclusion: always
---

# Project structure

```
Hauntcast-Weather/
├── .kiro/
│   ├── steering/              Project rules Kiro reads on every request (this folder)
│   ├── specs/<module>/        One spec per module: requirements.md, design.md, tasks.md
│   └── hooks/                 Agent hooks
├── apps/                      Django apps, one per domain. Each has repositories.py (Supabase access)
│   ├── users/                 profiles, user_locations
│   ├── locations/             countries, locations + location endpoints
│   ├── weather/               weather_categories (hazard catalog), weather_observations (forecast cache)
│   ├── alerts/                weather_alerts (normalized alerts, cache and history)
│   ├── recommendations/       prevention_recommendations
│   └── notifications/         notifications (optional M7)
├── config/                    Django settings and root urls
├── core/                      Supabase client and the base SupabaseRepository
├── integrations/
│   └── weather_providers/     base.py (WeatherProvider protocol + HazardAlert) and one module per source:
│                              senamhi.py, nws.py, smn.py, open_meteo.py, usgs.py
├── services/
│   ├── alert_engine.py        Picks providers by country, merges, deduplicates, computes the overall level
│   ├── risk_scale.py          Maps every source's levels to the 0–4 Skull Scale
│   └── notification_service.py
├── supabase/                  schema.sql and seed_*.sql files
├── frontend/                  Vite + React app
│   └── src/
│       ├── mocks/             JSON mocks that follow the API contract
│       ├── components/        RiskBadge, HazardScene, AlertCard, ...
│       └── animations/<slug>/ Phase 2 animation assets, one folder per hazard slug
├── docs/
│   ├── api-contract.md        Endpoints and response shapes (changes need approval from both teammates)
│   └── bitacora-kiro.md       Log of how Kiro was used (feeds the hackathon write-up)
└── README.md                  Full plan in Spanish
```

## Where new code goes

- A new data source → a new module in `integrations/weather_providers/` implementing `WeatherProvider`,
  plus its fixtures and tests. Register it in `services/alert_engine.py`.
- Level conversions → only in `services/risk_scale.py`. Providers call it; they never invent their own scale.
- A new endpoint → the `views.py` and `urls.py` of the app that owns the data, included in `config/urls.py`
  under `/api/v1/`.
- Database access → only through the app's `repositories.py`. Views and services never call `supabase.table()` directly.
- Hazard animations → `frontend/src/animations/<slug>/`, using the exact slug from `hazards.md`.

## Ownership

- Backend (`apps/`, `services/`, `integrations/`, `core/`, `config/`): Gabriel.
- `frontend/`: shared. Each teammate works on different screens or components at a time.
- `docs/api-contract.md` and `.kiro/steering/hazards.md`: changed only through a PR approved by both.
