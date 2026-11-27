# core/exceptions.py
from __future__ import annotations

from functools import wraps
from typing import Callable

from rest_framework import status
from rest_framework.response import Response

from core.supabase_client import SupabaseNotConfiguredError


def handle_supabase_unavailable(view_func: Callable) -> Callable:
    """Decorator that converts any Supabase-related failure into HTTP 503.

    Catches:
    - ``SupabaseNotConfiguredError``: credentials absent from the environment.
    - ``postgrest.exceptions.APIError``: the PostgREST layer rejected the query
      (e.g. unknown column, RLS violation, connection failure).
    - ``httpx.HTTPError``: network-level error reaching Supabase.

    All three produce the same 503 shape so the frontend can handle them
    uniformly.  The ``detail`` field differs so server logs stay useful.

    Usage::

        class MyView(APIView):
            @handle_supabase_unavailable
            def get(self, request):
                ...
    """

    @wraps(view_func)
    def wrapper(*args, **kwargs):
        try:
            return view_func(*args, **kwargs)
        except SupabaseNotConfiguredError:
            return Response(
                {
                    "error": "Data source unavailable",
                    "detail": "Supabase credentials not configured",
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except Exception as exc:  # noqa: BLE001
            # Lazily import to avoid a hard dependency at module load time.
            try:
                from postgrest.exceptions import APIError as PostgRESTError
            except ImportError:
                PostgRESTError = None  # type: ignore[assignment]

            try:
                import httpx
                HttpxError = httpx.HTTPError
            except ImportError:
                HttpxError = None  # type: ignore[assignment]

            is_postgrest = PostgRESTError is not None and isinstance(exc, PostgRESTError)
            is_httpx = HttpxError is not None and isinstance(exc, HttpxError)

            if is_postgrest or is_httpx:
                return Response(
                    {
                        "error": "Data source unavailable",
                        "detail": str(exc),
                    },
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            raise

    return wrapper
