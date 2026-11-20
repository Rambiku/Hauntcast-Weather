from core.supabase_client import supabase

try:
    response = supabase.table("countries").select("*").limit(5).execute()

    print("✅ Conexión exitosa con Supabase")
    print("Datos encontrados:", response.data)

except Exception as e:
    print("❌ Error de conexión:")
    print(e)