from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    GROQ_API_KEY: str
    # Pinecone and HuggingFace are optional until the RAG pipeline is wired in.
    # Leaving them unset will not crash on import.
    PINECONE_API_KEY: Optional[str] = None
    PINECONE_INDEX_NAME: str = "vespera-index"
    HF_TOKEN: Optional[str] = None

    class Config:
        env_file = ".env"


settings = Settings()
