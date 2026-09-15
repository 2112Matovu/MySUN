from functools import lru_cache

from supabase import Client, create_client

from app.core.config import get_settings


@lru_cache
def get_supabase_admin() -> Client:
    """Service-role client — bypasses Row Level Security. Server-side only;
    every privileged check (role, ownership) must happen in our own code
    before a request reaches this client, since RLS won't stop it."""
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


@lru_cache
def get_supabase_anon() -> Client:
    """Anon-key client — used only to proxy Supabase Auth sign-up/sign-in,
    which enforces Supabase's own auth rules regardless of key."""
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_anon_key)
