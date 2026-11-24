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
    ``hazard`` must be one of the 23 slugs defined in .kiro/steering/hazards.md.
    """

    id: str
    hazard: str                           # one of the 23 slugs in hazards.md
    level: int                            # 0–4 Skull Scale
    kind: str                             # "official" | "estimated"
    source: str                           # e.g. "senamhi", "nws", "open_meteo"
    title: str
    description: str
    official_recommendation: str | None   # SENAMHI RECOMENDAC or NWS instruction
    area_name: str | None
    starts_at: str                        # UTC ISO 8601
    ends_at: str | None                   # UTC ISO 8601 or None
    source_url: str | None


@dataclasses.dataclass
class ProviderResult:
    """Outcome of a single provider fetch.

    When ``ok`` is True the fetch succeeded; ``alerts`` may be empty (meaning
    the source was reachable but found no active hazards for that point) and
    ``error`` is None.

    When ``ok`` is False the fetch failed; ``alerts`` is always an empty list
    and ``error`` contains a human-readable description of the failure.

    The alert engine (M4) uses ``ok`` and ``error`` to populate the
    ``sources_status`` array in the /api/v1/risk response, so the frontend can
    distinguish "no hazards" from "source unavailable" and comply with the
    "Never fake calm" principle from the product steering.
    """

    source: str              # provider name, matches HazardAlert.source
    ok: bool
    alerts: list[HazardAlert]
    error: str | None        # None when ok=True; descriptive message when ok=False


class WeatherProvider(Protocol):
    """Protocol that every data-source adapter must satisfy.

    Implementations live in ``integrations/weather_providers/`` and must be
    registered in ``services/alert_engine.py``.
    """

    name: str  # e.g. "senamhi", "nws", "open_meteo"

    def covers(self, country_code: str) -> bool:
        """Return True if this provider has data for the given ISO-3166-1 alpha-2 country code."""
        ...

    def fetch_alerts(self, lat: float, lon: float) -> ProviderResult:
        """Return alerts for the given coordinates.

        Contract (MUST be followed by every implementation):

        - This method MUST NOT raise any exception to the caller.
          All errors — network timeouts, malformed responses, missing
          credentials, HTTP non-2xx, etc. — must be caught internally.
        - On failure: return ProviderResult(source=self.name, ok=False,
          alerts=[], error="<human-readable description>").
        - On success with no active alerts: return ProviderResult(
          source=self.name, ok=True, alerts=[], error=None).
          This is a valid, successful result that means the source was
          reachable and found no active hazards for that location.
        - Never return ok=True with an empty alerts list to mask a failure.
          The alert engine relies on ok=False to surface source failures and
          prevent "Never fake calm" violations.
        """
        ...
