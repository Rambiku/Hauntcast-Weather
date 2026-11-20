from core.supabase_repository import SupabaseRepository


class WeatherCategoryRepository(SupabaseRepository):
    table_name = "weather_categories"


class WeatherObservationRepository(SupabaseRepository):
    table_name = "weather_observations"
