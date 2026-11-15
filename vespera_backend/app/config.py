from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    GROQ_API_KEY: Optional[str] = None
    # Retired llama3-8b-8192 must not be hard-coded in callers. Validate this
    # ID against Groq's current model list at setup/release (VSP-010).
    GROQ_MODEL: str = "llama-3.1-8b-instant"
    # Pinecone and HuggingFace are optional until the RAG pipeline is wired in.
    # Leaving them unset will not crash on import.
    PINECONE_API_KEY: Optional[str] = None
    PINECONE_INDEX_NAME: str = "vespera-index"
    HF_TOKEN: Optional[str] = None
    JAMENDO_CLIENT_ID: Optional[str] = None
    JAMENDO_TERMS_CONFIRMED_ON: Optional[str] = None
    # VSP-007: PostgreSQL for production, SQLite for tests/local offline dev.
    # Override with:  DATABASE_URL=postgresql+asyncpg://user:pass@host/dbname
    DATABASE_URL: str = "sqlite+aiosqlite:///./vespera.db"
    # Legacy .env fields used by main.py Spotify/Groq init; kept here so
    # pydantic-settings does not reject them as extra inputs.
    SPOTIPY_CLIENT_ID: Optional[str] = None
    SPOTIPY_CLIENT_SECRET: Optional[str] = None
    ALLOWED_ORIGINS: str = "http://localhost:8080"

    class Config:
        env_file = ".env"


settings = Settings()
