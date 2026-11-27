# apps/weather/views.py
from __future__ import annotations

import re
from typing import Any

from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from core.exceptions import handle_supabase_unavailable

from .repositories import HazardCategoryRepository

# ---------------------------------------------------------------------------
# In-process cache: the hazard catalog is static for the life of the server
# process.  None = not yet loaded (an empty list would be ambiguous).
# ---------------------------------------------------------------------------
_catalog_cache: list[dict[str, Any]] | None = None

# Parses "group:water | mvp:true | ..." from the description column.
_GROUP_RE = re.compile(r"group:(\w+)")
_MVP_RE = re.compile(r"mvp:(true|false)")


def _parse_description(description: str | None) -> tuple[str, bool]:
    """Extract group and mvp flag from the description field.

    The seed stores metadata as ``"group:water | mvp:true | ..."``.
    Returns ``("", False)`` for rows that do not follow this format.
    """
    if not description:
        return "", False
    group_match = _GROUP_RE.search(description)
    mvp_match = _MVP_RE.search(description)
    group = group_match.group(1) if group_match else ""
    mvp = mvp_match.group(1) == "true" if mvp_match else False
    return group, mvp


def _build_hazard_payload(row: dict[str, Any]) -> dict[str, Any]:
    """Map a weather_categories row to the API contract shape.

    Schema columns used: code, name, description.
    ``name`` is the English hazard name (single language — frontend handles i18n).
    ``group`` and ``mvp`` are parsed from the ``description`` field.
    """
    group, mvp = _parse_description(row.get("description"))
    return {
        "slug": row.get("code", ""),
        "name_en": row.get("name", ""),
        "group": group,
        "mvp": mvp,
    }


class HazardListView(APIView):
    """GET /api/v1/hazards

    Returns the full hazard catalog. Response is cached in memory after the
    first successful fetch; Supabase is never called more than once per
    server process.

    Responses
    ---------
    200  {"hazards": [{slug, name_en, group, mvp}, ...]}
    503  {"error": "Data source unavailable", "detail": "..."}
    """

    @handle_supabase_unavailable
    def get(self, request: Request) -> Response:
        global _catalog_cache

        if _catalog_cache is None:
            repo = HazardCategoryRepository()
            rows = repo.list_all()
            _catalog_cache = [_build_hazard_payload(r) for r in rows]

        return Response({"hazards": _catalog_cache}, status=status.HTTP_200_OK)
