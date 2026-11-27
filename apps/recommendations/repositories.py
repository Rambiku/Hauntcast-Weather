# apps/recommendations/repositories.py
from __future__ import annotations

from typing import Any

from core.supabase_client import get_client
from core.supabase_repository import SupabaseRepository


class RecommendationRepository(SupabaseRepository):
    """Read access to the prevention_recommendations table.

    Relevant schema columns (supabase/schema.sql):
        id           uuid PK (generated)
        category_id  uuid FK → weather_categories.id
        severity     varchar(20) CHECK IN (INFO, LOW, MODERATE, HIGH, CRITICAL)
        title        varchar(200)  format: "<Phase> · <country_code> · <source>"
        description  text          action text in English
        created_at   timestamptz

    The seed stores one row per action.  ``title`` encodes phase, country and
    source: ``"Before · PE · INDECI"``.  ``get_by_slug_and_country`` resolves
    the category UUID, fetches matching rows filtered by country token in
    ``title``, and groups them into ``{before, during, after, source}``.
    """

    table_name = "prevention_recommendations"

    def get_by_slug_and_country(
        self, hazard_slug: str, country_code: str
    ) -> dict[str, Any] | None:
        """Return grouped before/during/after lists for a hazard+country pair.

        Resolves category UUID from weather_categories.code = hazard_slug,
        fetches rows whose title matches ``"% · <country_code> · %"``, groups
        them by phase prefix and returns ``{before, during, after, source}``,
        or None when no rows exist.

        Args:
            hazard_slug:  one of the 23 canonical slugs.
            country_code: ISO 3166-1 alpha-2 in uppercase (e.g. "PE").

        Raises:
            SupabaseNotConfiguredError: propagated from get_client().
        """
        client = get_client()

        # Step 1: resolve category UUID from slug.
        cat = (
            client.table("weather_categories")
            .select("id")
            .eq("code", hazard_slug)
            .maybe_single()
            .execute()
            .data
        )
        if not cat:
            return None

        category_id = cat["id"]

        # Step 2: fetch rows for this category filtered by country token in title.
        rows = (
            client.table(self.table_name)
            .select("title, description")
            .eq("category_id", category_id)
            .like("title", f"% · {country_code} · %")
            .execute()
            .data
            or []
        )

        if not rows:
            return None

        # Step 3: group rows by phase prefix (Before / During / After).
        before: list[str] = []
        during: list[str] = []
        after: list[str] = []
        source = ""

        for row in rows:
            title: str = row.get("title", "")
            description: str = row.get("description", "")

            # Extract source from title: "Before · PE · INDECI" → "INDECI"
            parts = [p.strip() for p in title.split("·")]
            if len(parts) == 3 and not source:
                source = parts[2]

            phase = parts[0].strip().lower() if parts else ""
            if phase == "before":
                before.append(description)
            elif phase == "during":
                during.append(description)
            elif phase == "after":
                after.append(description)

        return {
            "before": before,
            "during": during,
            "after": after,
            "source": source,
        }

    def list_by_hazard(self, hazard_slug: str) -> list[dict[str, Any]]:
        """Return all raw rows for a hazard (all countries, all phases).

        Used by M4 to build the recommendations block in /api/v1/risk.

        Raises:
            SupabaseNotConfiguredError: propagated from get_client().
        """
        client = get_client()

        cat = (
            client.table("weather_categories")
            .select("id")
            .eq("code", hazard_slug)
            .maybe_single()
            .execute()
            .data
        )
        if not cat:
            return []

        return (
            client.table(self.table_name)
            .select("title, description, severity")
            .eq("category_id", cat["id"])
            .execute()
            .data
            or []
        )


class EmergencyNumberRepository(SupabaseRepository):
    """Read access to the emergency_numbers table.

    Relevant schema columns (supabase/schema.sql):
        country_code  text PK (part)  CHECK ~ '^[A-Z]{2}$'
        label         text
        number        text PK (part)
        source_name   text
        source_url    text
        verified_at   date
    """

    table_name = "emergency_numbers"

    def list_by_country(self, country_code: str) -> list[dict[str, Any]]:
        """Return label and number for every emergency number in a country.

        Args:
            country_code: ISO 3166-1 alpha-2 in uppercase (e.g. "PE").

        Raises:
            SupabaseNotConfiguredError: propagated from get_client().
        """
        return (
            get_client()
            .table(self.table_name)
            .select("label, number")
            .eq("country_code", country_code)
            .execute()
            .data
            or []
        )
