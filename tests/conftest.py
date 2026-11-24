# tests/conftest.py
"""Shared pytest fixtures for Hauntcast Weather tests."""
from __future__ import annotations

import pytest


@pytest.fixture()
def supabase_env(monkeypatch):
    """Set fake Supabase credentials in the environment for tests that need them.

    Resets the lazy singleton after each test to avoid cross-test state pollution.
    """
    monkeypatch.setenv("SUPABASE_URL", "https://fake.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "fake-service-role-key")

    import core.supabase_client as sc
    original = sc._client
    sc._client = None

    yield

    sc._client = original


@pytest.fixture()
def no_supabase_env(monkeypatch):
    """Remove Supabase credentials from the environment.

    Resets the lazy singleton after each test.
    """
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.delenv("SUPABASE_KEY", raising=False)

    import core.supabase_client as sc
    original = sc._client
    sc._client = None

    yield

    sc._client = original
