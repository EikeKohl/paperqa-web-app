import logging
from typing import Union

import requests
from cloudpathlib import AnyPath
from haystack.document_stores import FAISSDocumentStore
from haystack.nodes import EmbeddingRetriever, OpenAIAnswerGenerator, PreProcessor
from haystack.pipelines import GenerativeQAPipeline
from haystack.utils import convert_files_to_docs, print_answers
from pydantic import BaseSettings, Field

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler("app.log"), logging.StreamHandler()],
)


class QASettings(BaseSettings):
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


def get_retriever(document_store):
    return EmbeddingRetriever(
        document_store=document_store,
        embedding_model=settings.retriever_model,
        batch_size=32,
        api_key=settings.openapi_key,
        max_seq_len=1024,
    )


def get_qa_pipeline(
    settings: QASettings, papers: list
) -> Union[FAISSDocumentStore, GenerativeQAPipeline]:
    if (
        settings.faiss_index_path.exists()
        and settings.faiss_config_path.exists()
        and settings.faiss_db_path.exists()
    ):
        document_store = FAISSDocumentStore.load(
            index_path=settings.faiss_index_path, config_path=settings.faiss_config_path
        )

        retriever = get_retriever(document_store)

    else:
        document_store = FAISSDocumentStore(
            faiss_index_factory_str="Flat",
            embedding_dim=settings.embedding_dim,
            sql_url=f"sqlite:///{settings.faiss_db_path.as_posix()}",
        )

        retriever = get_retriever(document_store)

        for paper in papers:
            download_pdf(paper, settings.external_doc_dir)

        processed_paper = prepare_paper(settings)

        document_store.write_documents(processed_paper)
        document_store.update_embeddings(
            retriever=retriever, update_existing_embeddings=False
        )
        document_store.save(
            index_path=settings.faiss_index_path, config_path=settings.faiss_config_path
        )

    generator = OpenAIAnswerGenerator(
        api_key=settings.openapi_key,
        model=settings.generator_model,
        temperature=settings.temperature,
        max_tokens=settings.generator_max_tokens,
        # prompt_template=settings.prompt_template,
    )

    qa_pipeline = GenerativeQAPipeline(generator=generator, retriever=retriever)

    return qa_pipeline


def prepare_paper(settings):
    docs = convert_files_to_docs(
        dir_path=settings.external_doc_dir, clean_func=None, split_paragraphs=False
    )

    preprocessor = PreProcessor(
        clean_empty_lines=False,
        clean_whitespace=False,
        clean_header_footer=False,
        split_by="sentence",
        split_length=2,
        split_overlap=0,
        split_respect_sentence_boundary=False,
        language="en",
    )
    processed_docs = preprocessor.process(docs)
    return processed_docs


def download_pdf(pdf_url, save_dir):
    downloaded_pdf = AnyPath(save_dir) / pdf_url.split("/")[-1]
    if not downloaded_pdf.exists():
        downloaded_pdf.write_bytes(requests.get(pdf_url).content)


if __name__ == "__main__":
    PAPERS = ["https://arxiv.org/pdf/1603.03627.pdf"]
    settings = QASettings()

    pipeline = get_qa_pipeline(settings, PAPERS)

    params = {
        "Retriever": {"top_k": 5},
        "Generator": {"top_k": 1},
    }

    answer = pipeline.run(
        query="Please summarize what a dynamically "
        "weighted conditional random field is",
        params=params,
    )
    print_answers(answer, details="minimum")
