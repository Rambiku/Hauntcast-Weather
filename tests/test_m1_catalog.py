# tests/test_m1_catalog.py
"""Tests for M1 · Hazard catalog and recommendations.

Coverage:
  R5 — GET /api/v1/hazards
  R6 — GET /api/v1/recommendations
  R7 — routes registered in config/urls.py

All Supabase calls are mocked with unittest.mock.patch;
no live connection is required.
"""
from __future__ import annotations

from unittest.mock import patch

import pytest
from rest_framework.test import APIRequestFactory

from apps.weather.constants import VALID_HAZARD_SLUGS, MVP_HAZARD_SLUGS

factory = APIRequestFactory()

# ---------------------------------------------------------------------------
# Shared fake data
# ---------------------------------------------------------------------------

def _make_hazard_row(code: str, name: str, group: str, mvp: bool) -> dict:
    return {
        "id": f"uuid-{code}",
        "code": code,
        "name": name,
        "description": f"group:{group} | mvp:{'true' if mvp else 'false'} | text",
        "animation_key": code,
        "created_at": "2026-11-25T00:00:00Z",
    }


ALL_FAKE_ROWS = [
    _make_hazard_row("lluvia_intensa",    "Heavy rain",           "water",          True),
    _make_hazard_row("huayco",            "Debris flows",         "water",          True),
    _make_hazard_row("inundacion",        "Floods",               "water",          True),
    _make_hazard_row("tormenta_electrica","Thunderstorms",        "water",          True),
    _make_hazard_row("granizo",           "Hail",                 "water",          False),
    _make_hazard_row("deslizamiento",     "Landslides",           "water",          False),
    _make_hazard_row("helada",            "Frost",                "cold_heat",      True),
    _make_hazard_row("ola_calor",         "Heat wave",            "cold_heat",      True),
    _make_hazard_row("radiacion_uv",      "Extreme UV radiation", "cold_heat",      True),
    _make_hazard_row("nevada",            "Snow and blizzards",   "cold_heat",      False),
    _make_hazard_row("friaje",            "Cold surge (Amazon)",  "cold_heat",      False),
    _make_hazard_row("viento_fuerte",     "Strong winds",         "wind_sea",       True),
    _make_hazard_row("ciclon_tropical",   "Tropical cyclone",     "wind_sea",       True),
    _make_hazard_row("tornado",           "Tornado",              "wind_sea",       True),
    _make_hazard_row("oleaje",            "Abnormal waves",       "wind_sea",       False),
    _make_hazard_row("tsunami",           "Tsunami",              "wind_sea",       False),
    _make_hazard_row("sismo",             "Earthquake",           "earth_fire_air", True),
    _make_hazard_row("incendio_forestal", "Wildfire",             "earth_fire_air", False),
    _make_hazard_row("volcan",            "Volcanic activity",    "earth_fire_air", False),
    _make_hazard_row("niebla",            "Dense fog",            "earth_fire_air", False),
    _make_hazard_row("polvo",             "Dust storm",           "earth_fire_air", False),
    _make_hazard_row("calidad_aire",      "Poor air quality",     "earth_fire_air", False),
    _make_hazard_row("sequia",            "Drought",              "earth_fire_air", False),
]

FAKE_RECOMMENDATION = {
    "before": ["Identify safe evacuation routes.", "Prepare an emergency kit."],
    "during": ["Move away from ravines immediately.", "Do not cross flooded roads."],
    "after":  ["Do not return until authorities confirm it is safe.", "Disinfect surfaces."],
    "source": "INDECI",
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _hazard_view(request):
    from apps.weather.views import HazardListView
    return HazardListView.as_view()(request)


def _rec_view(params):
    from apps.recommendations.views import RecommendationDetailView
    return RecommendationDetailView.as_view()(
        factory.get("/api/v1/recommendations", params)
    )


# ---------------------------------------------------------------------------
# R7 · Routes
# ---------------------------------------------------------------------------

class TestRoutes:
    """R7 — routes registered in config/urls.py."""

    def test_hazard_list_url_resolves(self):
        from django.urls import reverse
        assert reverse("hazard-list") == "/api/v1/hazards"

    def test_recommendation_detail_url_resolves(self):
        from django.urls import reverse
        assert reverse("recommendation-detail") == "/api/v1/recommendations"


# ---------------------------------------------------------------------------
# R5 · GET /api/v1/hazards
# ---------------------------------------------------------------------------

class TestHazardListView:
    """R5 — GET /api/v1/hazards."""

    @pytest.fixture(autouse=True)
    def _reset_cache(self):
        import apps.weather.views as wv
        wv._catalog_cache = None
        yield
        wv._catalog_cache = None

    # ── happy path ───────────────────────────────────────────────────────────

    def test_returns_200_with_all_23_hazards(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        assert resp.status_code == 200
        assert "hazards" in resp.data
        assert len(resp.data["hazards"]) == 23

    def test_all_23_slugs_present(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        returned_slugs = {h["slug"] for h in resp.data["hazards"]}
        assert returned_slugs == VALID_HAZARD_SLUGS

    def test_exactly_11_mvp_hazards(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        mvp_slugs = {h["slug"] for h in resp.data["hazards"] if h["mvp"] is True}
        assert mvp_slugs == MVP_HAZARD_SLUGS

    def test_payload_shape_no_extra_fields(self):
        """Every item has exactly slug, name_en, group, mvp — no extras."""
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        for item in resp.data["hazards"]:
            assert set(item.keys()) == {"slug", "name_en", "group", "mvp"}

    def test_no_name_es_field(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        for item in resp.data["hazards"]:
            assert "name_es" not in item

    def test_no_icon_field(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        for item in resp.data["hazards"]:
            assert "icon" not in item

    def test_group_parsed_from_description(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        by_slug = {h["slug"]: h for h in resp.data["hazards"]}
        assert by_slug["huayco"]["group"]          == "water"
        assert by_slug["sismo"]["group"]           == "earth_fire_air"
        assert by_slug["tornado"]["group"]         == "wind_sea"
        assert by_slug["helada"]["group"]          == "cold_heat"

    def test_name_en_read_from_name_column(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            resp = _hazard_view(factory.get("/api/v1/hazards"))

        by_slug = {h["slug"]: h for h in resp.data["hazards"]}
        assert by_slug["lluvia_intensa"]["name_en"] == "Heavy rain"
        assert by_slug["sismo"]["name_en"]          == "Earthquake"

    # ── cache ────────────────────────────────────────────────────────────────

    def test_cache_populated_after_first_request(self):
        import apps.weather.views as wv
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS):
            assert wv._catalog_cache is None
            _hazard_view(factory.get("/api/v1/hazards"))
            assert wv._catalog_cache is not None

    def test_supabase_called_only_once_for_two_requests(self):
        with patch("apps.weather.views.HazardCategoryRepository.list_all",
                   return_value=ALL_FAKE_ROWS) as mock_list:
            _hazard_view(factory.get("/api/v1/hazards"))
            _hazard_view(factory.get("/api/v1/hazards"))

        assert mock_list.call_count == 1

    # ── error handling ───────────────────────────────────────────────────────

    def test_503_when_supabase_not_configured(self, no_supabase_env):
        resp = _hazard_view(factory.get("/api/v1/hazards"))

        assert resp.status_code == 503
        assert resp.data["error"] == "Data source unavailable"

    def test_503_body_never_has_hazards_key(self, no_supabase_env):
        resp = _hazard_view(factory.get("/api/v1/hazards"))

        assert resp.status_code == 503
        assert "hazards" not in resp.data


# ---------------------------------------------------------------------------
# R6 · GET /api/v1/recommendations
# ---------------------------------------------------------------------------

class TestRecommendationDetailView:
    """R6 — GET /api/v1/recommendations."""

    # ── parameter validation — 400 ───────────────────────────────────────────

    def test_400_missing_hazard(self):
        resp = _rec_view({})
        assert resp.status_code == 400
        assert resp.data["error"] == "Missing required parameter: hazard"

    def test_400_missing_country(self):
        resp = _rec_view({"hazard": "huayco"})
        assert resp.status_code == 400
        assert resp.data["error"] == "Missing required parameter: country"

    def test_400_invalid_slug(self):
        resp = _rec_view({"hazard": "not_a_real_slug", "country": "PE"})
        assert resp.status_code == 400
        assert resp.data["error"] == "Invalid hazard slug"

    @pytest.mark.parametrize("bad_country", ["pe", "Per", "PER", "1E", "P1"])
    def test_400_invalid_country_code(self, bad_country):
        resp = _rec_view({"hazard": "huayco", "country": bad_country})
        assert resp.status_code == 400
        assert resp.data["error"] == "Invalid country code"

    def test_400_does_not_reach_repository(self):
        """Validation errors must short-circuit before any Supabase call."""
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country"
        ) as mock_get:
            _rec_view({"hazard": "bad_slug", "country": "PE"})
            mock_get.assert_not_called()

    # ── not found — 404 ──────────────────────────────────────────────────────

    def test_404_when_no_rows_for_combination(self):
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=None,
        ):
            resp = _rec_view({"hazard": "huayco", "country": "ZZ"})

        assert resp.status_code == 404
        assert resp.data["error"] == "No recommendations found"
        assert resp.data["hazard"] == "huayco"
        assert resp.data["country"] == "ZZ"

    # ── happy path — 200 ─────────────────────────────────────────────────────

    def test_200_returns_all_contract_fields(self):
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ):
            resp = _rec_view({"hazard": "huayco", "country": "PE"})

        assert resp.status_code == 200
        assert set(resp.data.keys()) == {"hazard", "country", "before", "during", "after", "source"}

    def test_200_hazard_and_country_echoed(self):
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ):
            resp = _rec_view({"hazard": "sismo", "country": "MX"})

        assert resp.data["hazard"] == "sismo"
        assert resp.data["country"] == "MX"

    def test_200_before_during_after_non_empty(self):
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ):
            resp = _rec_view({"hazard": "huayco", "country": "PE"})

        assert len(resp.data["before"]) >= 2
        assert len(resp.data["during"]) >= 1
        assert len(resp.data["after"]) >= 1

    def test_200_source_field_set(self):
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ):
            resp = _rec_view({"hazard": "huayco", "country": "PE"})

        assert resp.data["source"] == "INDECI"

    def test_200_actions_are_english(self):
        """Spot-check that action text contains no Spanish."""
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ):
            resp = _rec_view({"hazard": "huayco", "country": "PE"})

        all_actions = resp.data["before"] + resp.data["during"] + resp.data["after"]
        spanish_markers = ["aléjate", "mantente", "no cruces", "desinfecta"]
        for action in all_actions:
            for marker in spanish_markers:
                assert marker not in action.lower(), (
                    f"Spanish text found: {action!r}"
                )

    def test_repository_called_with_correct_args(self):
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ) as mock_get:
            _rec_view({"hazard": "sismo", "country": "US"})

        mock_get.assert_called_once_with("sismo", "US")

    # ── all 11 MVP slugs accepted ────────────────────────────────────────────

    @pytest.mark.parametrize("slug", sorted(MVP_HAZARD_SLUGS))
    def test_mvp_slugs_pass_validation(self, slug):
        """Every MVP slug must pass validation and reach the repository."""
        with patch(
            "apps.recommendations.views.RecommendationRepository.get_by_slug_and_country",
            return_value=FAKE_RECOMMENDATION,
        ):
            resp = _rec_view({"hazard": slug, "country": "US"})

        assert resp.status_code == 200

    # ── error handling — 503 ─────────────────────────────────────────────────

    def test_503_when_supabase_not_configured(self, no_supabase_env):
        resp = _rec_view({"hazard": "huayco", "country": "PE"})

        assert resp.status_code == 503
        assert resp.data["error"] == "Data source unavailable"

    def test_503_body_has_detail_field(self, no_supabase_env):
        resp = _rec_view({"hazard": "huayco", "country": "PE"})

        assert "detail" in resp.data


# ---------------------------------------------------------------------------
# R5 · _parse_description unit tests
# ---------------------------------------------------------------------------

class TestParseDescription:
    """Unit tests for the description-parsing helper in weather/views.py."""

    def test_parses_group_water(self):
        from apps.weather.views import _parse_description
        group, _ = _parse_description("group:water | mvp:true | text")
        assert group == "water"

    def test_parses_group_earth_fire_air(self):
        from apps.weather.views import _parse_description
        group, _ = _parse_description("group:earth_fire_air | mvp:false | text")
        assert group == "earth_fire_air"

    @pytest.mark.parametrize("group", ["water", "cold_heat", "wind_sea", "earth_fire_air"])
    def test_all_valid_groups_round_trip(self, group):
        from apps.weather.views import _parse_description
        parsed_group, _ = _parse_description(f"group:{group} | mvp:false | x")
        assert parsed_group == group

    def test_mvp_true(self):
        from apps.weather.views import _parse_description
        _, mvp = _parse_description("group:water | mvp:true | x")
        assert mvp is True

    def test_mvp_false(self):
        from apps.weather.views import _parse_description
        _, mvp = _parse_description("group:water | mvp:false | x")
        assert mvp is False

    def test_none_returns_defaults(self):
        from apps.weather.views import _parse_description
        group, mvp = _parse_description(None)
        assert group == "" and mvp is False

    def test_empty_string_returns_defaults(self):
        from apps.weather.views import _parse_description
        group, mvp = _parse_description("")
        assert group == "" and mvp is False

    def test_malformed_description_returns_defaults(self):
        from apps.weather.views import _parse_description
        group, mvp = _parse_description("no metadata here")
        assert group == "" and mvp is False
