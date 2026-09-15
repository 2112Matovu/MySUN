from typing import Any

from fastapi import HTTPException, status

from app.core.supabase_client import get_supabase_admin


class TableRepo:
    """Thin wrapper around one Supabase table for simple CRUD. Role and
    ownership checks happen in the route layer *before* calling these
    methods — this always uses the service-role client, so it bypasses RLS."""

    def __init__(self, table: str):
        self.table = table

    def list(
        self,
        order_by: str = "id",
        desc: bool = False,
        **filters: Any,
    ) -> list[dict]:
        query = get_supabase_admin().table(self.table).select("*")
        for key, value in filters.items():
            if value is not None:
                query = query.eq(key, value)
        return query.order(order_by, desc=desc).execute().data

    def get(self, id: str) -> dict:
        result = (
            get_supabase_admin().table(self.table).select("*").eq("id", id).maybe_single().execute()
        )
        if not result or not result.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, f"{self.table}/{id} not found")
        return result.data

    def create(self, data: dict) -> dict:
        result = get_supabase_admin().table(self.table).insert(data).execute()
        return result.data[0]

    def update(self, id: str, data: dict) -> dict:
        result = get_supabase_admin().table(self.table).update(data).eq("id", id).execute()
        if not result.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, f"{self.table}/{id} not found")
        return result.data[0]

    def delete(self, id: str) -> None:
        get_supabase_admin().table(self.table).delete().eq("id", id).execute()
