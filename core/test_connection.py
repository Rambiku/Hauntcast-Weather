from core.supabase_client import get_client

try:
    response = get_client().table("countries").select("*").limit(5).execute()

    print("✅ Conexión exitosa con Supabase")
    print("Datos encontrados:", response.data)

except Exception as e:
    print("❌ Error de conexión:")
    print(e)