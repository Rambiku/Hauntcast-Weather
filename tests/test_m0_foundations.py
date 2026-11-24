# tests/test_m0_foundations.py
"""Unit tests for M0 · Cimientos foundations.

Tests verify settings correctness, the lazy Supabase singleton,
and the 503 behavior when credentials are absent.
"""
from __future__ import annotations

import importlib
import sys

import pytest


class TestSupabaseClientImport:
    """15.1 — Importing core.supabase_client without env vars must not raise."""

    def test_import_without_credentials_does_not_raise(self, monkeypatch):
        """Importing the module is safe even when SUPABASE_URL and SUPABASE_KEY are absent."""
        monkeypatch.delenv("SUPABASE_URL", raising=False)
        monkeypatch.delenv("SUPABASE_KEY", raising=False)

        # Remove the module from sys.modules to force a fresh import
        sys.modules.pop("core.supabase_client", None)

        # This must not raise any exception
        import core.supabase_client  # noqa: F401

        # Re-add it to sys.modules so subsequent tests get a consistent state
        # (the module is now safely loaded)
