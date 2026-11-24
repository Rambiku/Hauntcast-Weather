from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from core.supabase_client import get_client, SupabaseNotConfiguredError
from core.exceptions import handle_supabase_unavailable


class SupabaseConnectionView(APIView):
    """Test endpoint to verify Supabase connectivity.

    Returns 503 if credentials are not configured (expected during local
    development without a .env file).
    Returns 200 with a sample of the countries table if connected.
    """

    @handle_supabase_unavailable
    def get(self, request):
        try:
            result = get_client().table("countries").select("*").limit(5).execute()
            return Response({
                "success": True,
                "message": "Conexión con Supabase exitosa",
                "data": result.data,
            })
        except SupabaseNotConfiguredError:
            # Handled by the decorator above; this branch is never reached.
            raise
        except Exception as e:
            return Response(
                {"success": False, "error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
