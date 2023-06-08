from pathlib import Path

import yaml
from pydantic import BaseSettings, Extra, Field


class QASettings(BaseSettings, extra=Extra.allow):
    external_doc_dir: Path = Field(
        "data", description="Directory to save the papers to"
    )
    openai_api_key: str = Field(
        ..., env="OPENAI_API_KEY", description="Api key for openai calls"
    )
    retriever_model: str = Field(..., description="Model to use for retrieving context")
    generator_model: str = Field(
        ..., description="Model to use to generate context backed answer"
    )
    retriever_embedding_dim: int = Field(
        ..., description="Embedding dimension for the document store"
    )
    temperature: float = Field(
        0.2, description="Temperature for the context backed answer generation"
    )
    generator_max_tokens: int = Field(
        1024, description="Max tokens for the context backed answer generation"
    )
    faiss_index_path: Path = Field("faiss_index.index")
    faiss_config_path: Path = Field("faiss_config.config")
    faiss_db_path: Path = Field("faiss_document_store.db")

    @staticmethod
    def init_settings(config_path):
        config = yaml.safe_load(Path(config_path).read_bytes())
        return QASettings.parse_obj(config)

    def update_from_session_state(self, session_state):
        for setting in ["temperature", "generator_max_tokens"]:
            self.__setattr__(setting, session_state.get(setting))
