from typing import Any

from core.supabase_client import supabase


class SupabaseRepository:
    """Small SDK-backed CRUD scaffold for a single public table."""

    table_name: str

    @property
    def table(self):
        return supabase.table(self.table_name)

    def list(self, columns: str = "*") -> list[dict[str, Any]]:
        return self.table.select(columns).execute().data or []

    def get(self, record_id: str) -> dict[str, Any] | None:
        return (
            self.table.select("*")
            .eq("id", record_id)
            .maybe_single()
            .execute()
            .data
        )

    def create(self, values: dict[str, Any]) -> list[dict[str, Any]]:
        return self.table.insert(values).select("*").execute().data or []

    def update(self, record_id: str, values: dict[str, Any]) -> list[dict[str, Any]]:
        return (
            self.table.update(values)
            .eq("id", record_id)
            .select("*")
            .execute()
            .data
            or []
        )

    def delete(self, record_id: str) -> list[dict[str, Any]]:
        return (
            self.table.delete()
            .eq("id", record_id)
            .select("*")
            .execute()
            .data
            or []
        )
