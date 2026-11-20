from core.supabase_repository import SupabaseRepository


class WeatherAlertRepository(SupabaseRepository):
    table_name = "weather_alerts"
