# apps/weather/repositories.py
from __future__ import annotations

from typing import Any

from core.supabase_client import get_client
from core.supabase_repository import SupabaseRepository


class HazardCategoryRepository(SupabaseRepository):
    """Read access to the weather_categories table.

    Relevant schema columns (supabase/schema.sql):
        id            uuid PK
        code          varchar(50) UNIQUE  ← canonical hazard slug
        name          varchar(100)        ← English hazard name
        description   text                ← "group:<g> | mvp:<bool> | <human text>"
        animation_key varchar(100)        ← equals code; matches frontend animation folder
        created_at    timestamptz
    """

    table_name = "weather_categories"

    def list_all(self) -> list[dict[str, Any]]:
        """Return every row in weather_categories.

        Raises:
            SupabaseNotConfiguredError: propagated from get_client().
        """
        return get_client().table(self.table_name).select("*").execute().data or []

    def get_by_slug(self, slug: str) -> dict[str, Any] | None:
        """Return the row whose ``code`` matches *slug*, or None if not found.

        Raises:
            SupabaseNotConfiguredError: propagated from get_client().
        """
        return (
            get_client()
            .table(self.table_name)
            .select("*")
            .eq("code", slug)
            .maybe_single()
            .execute()
            .data
        )


class WeatherObservationRepository(SupabaseRepository):
    table_name = "weather_observations"
