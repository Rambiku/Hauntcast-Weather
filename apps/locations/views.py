from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from core.supabase_client import supabase


class SupabaseConnectionView(APIView):

    def get(self, request):
        try:
            result = supabase.table("countries").select("*").limit(5).execute()

            return Response({
                "success": True,
                "message": "Conexión con Supabase exitosa",
                "data": result.data
            })

        except Exception as e:
            return Response({
                "success": False,
                "error": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)