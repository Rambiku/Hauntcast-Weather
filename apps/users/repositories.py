from core.supabase_repository import SupabaseRepository


class ProfileRepository(SupabaseRepository):
    table_name = "profiles"


class UserLocationRepository(SupabaseRepository):
    table_name = "user_locations"
