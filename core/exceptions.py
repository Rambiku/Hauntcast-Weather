# core/exceptions.py
from __future__ import annotations

from functools import wraps
from typing import Callable

from rest_framework import status
from rest_framework.response import Response

from core.supabase_client import SupabaseNotConfiguredError


def handle_supabase_unavailable(view_func: Callable) -> Callable:
    """Decorator that converts SupabaseNotConfiguredError into HTTP 503.

    Apply to any APIView method that uses the Supabase client.
    If the Supabase credentials are not configured, the decorator returns
    a 503 response before the view body executes.

    Usage::

        class MyView(APIView):
            @handle_supabase_unavailable
            def get(self, request):
                client = get_client()
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

    return wrapper
