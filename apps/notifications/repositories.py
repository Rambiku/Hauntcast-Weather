from core.supabase_repository import SupabaseRepository


class NotificationRepository(SupabaseRepository):
    table_name = "notifications"
