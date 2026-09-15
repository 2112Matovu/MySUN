from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str
    # Defaults to "production" (the restrictive CORS path in main.py) so a
    # deploy that forgets to set APP_ENV fails safe instead of opening CORS
    # to "*". Local dev must set APP_ENV=development explicitly (already
    # done in .env.example).
    app_env: str = "production"
    cors_origins: str = "http://localhost:5000"
    log_level: str = "INFO"
    sentry_dsn: str | None = None

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
