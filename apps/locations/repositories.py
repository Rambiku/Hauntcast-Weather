from core.supabase_repository import SupabaseRepository


class CountryRepository(SupabaseRepository):
    table_name = "countries"


class LocationRepository(SupabaseRepository):
    table_name = "locations"
