# core/supabase_client.py
from __future__ import annotations

import os
from pathlib import Path
from typing import TYPE_CHECKING

from dotenv import load_dotenv

if TYPE_CHECKING:
    from supabase import Client

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

_client: "Client | None" = None


class SupabaseNotConfiguredError(RuntimeError):
    """Raised when SUPABASE_URL or SUPABASE_KEY are not set in the environment.

    The module imports cleanly without credentials; this error is only raised
    when get_client() is actually called without the required env vars.
    """


def get_client() -> "Client":
    """Return the shared Supabase client, creating it on first call (lazy singleton).

    Raises:
        SupabaseNotConfiguredError: if SUPABASE_URL or SUPABASE_KEY are absent
            from the environment when this function is first called.
    """
    global _client
    if _client is None:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        if not url or not key:
            raise SupabaseNotConfiguredError(
                "SUPABASE_URL and SUPABASE_KEY must be set in the environment."
            )
        from supabase import create_client  # deferred to keep startup fast
        _client = create_client(url, key)
    return _client
