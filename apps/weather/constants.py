# apps/weather/constants.py
# Single source of truth for the 23 canonical hazard slugs.
# Import this set wherever a slug needs to be validated (views, tests, etc.)
# Do NOT add, remove or rename slugs without a PR approved by both teammates.

from __future__ import annotations

VALID_HAZARD_SLUGS: frozenset[str] = frozenset(
    {
        # water
        "lluvia_intensa",
        "huayco",
        "inundacion",
        "tormenta_electrica",
        "granizo",
        "deslizamiento",
        # cold_heat
        "helada",
        "ola_calor",
        "radiacion_uv",
        "nevada",
        "friaje",
        # wind_sea
        "viento_fuerte",
        "ciclon_tropical",
        "tornado",
        "oleaje",
        "tsunami",
        # earth_fire_air
        "sismo",
        "incendio_forestal",
        "volcan",
        "niebla",
        "polvo",
        "calidad_aire",
        "sequia",
    }
)

MVP_HAZARD_SLUGS: frozenset[str] = frozenset(
    {
        "lluvia_intensa",
        "huayco",
        "inundacion",
        "tormenta_electrica",
        "helada",
        "ola_calor",
        "radiacion_uv",
        "viento_fuerte",
        "ciclon_tropical",
        "tornado",
        "sismo",
    }
)
