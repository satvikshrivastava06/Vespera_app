from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    GROQ_API_KEY: str
    PINECONE_API_KEY: str
    PINECONE_INDEX_NAME: str = "vespera-index"
    HF_TOKEN: str

    class Config:
        env_file = ".env"

settings = Settings()
