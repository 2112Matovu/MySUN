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
    # Firebase service-account key (the JSON itself, or a path to it) for
    # push notifications. Unset = in-app notifications only.
    fcm_service_account_json: str | None = None
    # Runs the event-reminder job inside the API process every few minutes.
    # Turn off if an external scheduler hits /internal/run-reminders instead.
    reminders_enabled: bool = True
    # Shared secret for POST /internal/run-reminders (unset = endpoint off).
    cron_secret: str | None = None

    # When true, admin-level accounts must pass TOTP two-factor sign-in
    # (Supabase MFA) before any admin endpoint accepts them. Roll out by first
    # letting every admin enrol (Profile > Two-factor authentication).
    admin_require_2fa: bool = False

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
