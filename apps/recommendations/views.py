# apps/recommendations/views.py
from __future__ import annotations

import re

from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.weather.constants import VALID_HAZARD_SLUGS
from core.exceptions import handle_supabase_unavailable

from .repositories import RecommendationRepository

_COUNTRY_RE = re.compile(r"^[A-Z]{2}$")


class RecommendationDetailView(APIView):
    """GET /api/v1/recommendations?hazard=<slug>&country=<XX>

    Returns what to do before, during and after a specific hazard
    for the given country.

    Query parameters
    ----------------
    hazard   required  one of the 23 canonical slugs
    country  required  ISO 3166-1 alpha-2 (two uppercase letters, e.g. PE)

    Responses
    ---------
    200  {hazard, country, before, during, after, source}
    400  {"error": "Missing required parameter: hazard"}
    400  {"error": "Missing required parameter: country"}
    400  {"error": "Invalid hazard slug"}
    400  {"error": "Invalid country code"}
    404  {"error": "No recommendations found", "hazard": "...", "country": "..."}
    503  {"error": "Data source unavailable", "detail": "..."}
    """

    @handle_supabase_unavailable
    def get(self, request: Request) -> Response:
        hazard = request.query_params.get("hazard", "").strip()
        country = request.query_params.get("country", "").strip()

        # ── parameter presence ──────────────────────────────────────────────
        if not hazard:
            return Response(
                {"error": "Missing required parameter: hazard"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not country:
            return Response(
                {"error": "Missing required parameter: country"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ── parameter validation ────────────────────────────────────────────
        if hazard not in VALID_HAZARD_SLUGS:
            return Response(
                {"error": "Invalid hazard slug"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not _COUNTRY_RE.match(country):
            return Response(
                {"error": "Invalid country code"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ── data lookup ─────────────────────────────────────────────────────
        repo = RecommendationRepository()
        data = repo.get_by_slug_and_country(hazard, country)

        if data is None:
            return Response(
                {
                    "error": "No recommendations found",
                    "hazard": hazard,
                    "country": country,
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(
            {
                "hazard": hazard,
                "country": country,
                "before": data["before"],
                "during": data["during"],
                "after": data["after"],
                "source": data["source"],
            },
            status=status.HTTP_200_OK,
        )
