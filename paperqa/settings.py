from cloudpathlib import AnyPath
from pydantic import BaseSettings, Extra, Field


class QASettings(BaseSettings, extra=Extra.allow):
    external_doc_dir: AnyPath = Field("data", env="PATH_EXTERNAL_DOCS")
    openapi_key: str = Field(..., env="OPENAPI_KEY")
    openai_api_base: str = Field(
        description="Azure api base url in case you want to use Azure Openai"
    )
    retriever_model: str = Field("text-embedding-ada-002", env="RETRIEVER_MODEL")
    generator_model: str = Field("text-davinci-003", env="GENERATOR_MODEL")
    embedding_dim: int = Field(
        1536, description="Embedding dimension for the document store"
    )
    temperature: float = Field(0.2)
    generator_max_tokens: int = Field(1024)
    faiss_index_path: AnyPath = Field("faiss_index.index")
    faiss_config_path: AnyPath = Field("faiss_config.config")
    faiss_db_path: AnyPath = Field("faiss_document_store.db")
