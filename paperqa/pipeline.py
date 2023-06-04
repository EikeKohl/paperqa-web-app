from haystack.document_stores.faiss import FAISSDocumentStore
from haystack.nodes import EmbeddingRetriever, OpenAIAnswerGenerator, PreProcessor
from haystack.pipelines import GenerativeQAPipeline
from haystack.utils import convert_files_to_docs

from .settings import QASettings
from .utils import download_pdf


def get_retriever(document_store: FAISSDocumentStore, settings: QASettings):
    return EmbeddingRetriever(
        document_store=document_store,
        embedding_model=settings.retriever_model,
        batch_size=32,
        api_key=settings.openapi_key,
        max_seq_len=1024,
    )


def get_qa_pipeline(
    settings: QASettings, retriever: EmbeddingRetriever
) -> GenerativeQAPipeline:
    generator = OpenAIAnswerGenerator(
        api_key=settings.openapi_key,
        model=settings.generator_model,
        temperature=settings.temperature,
        max_tokens=settings.generator_max_tokens,
    )

    return GenerativeQAPipeline(generator=generator, retriever=retriever)


def prepare_papers(settings: QASettings):
    docs = convert_files_to_docs(
        dir_path=settings.external_doc_dir.as_posix(),
        clean_func=None,
        split_paragraphs=False,
    )

    preprocessor = PreProcessor(
        clean_empty_lines=False,
        clean_whitespace=False,
        clean_header_footer=False,
        split_by="sentence",
        split_length=4,
        split_overlap=0,
        split_respect_sentence_boundary=False,
        language="en",
    )
    return preprocessor.process(docs)


def update_documentstore(
    papers: list,
    settings: QASettings,
):
    if (
        settings.faiss_index_path.exists()
        and settings.faiss_config_path.exists()
        and settings.faiss_db_path.exists()
    ):
        document_store = FAISSDocumentStore.load(
            index_path=settings.faiss_index_path, config_path=settings.faiss_config_path
        )

    else:
        document_store = FAISSDocumentStore(
            faiss_index_factory_str="Flat",
            embedding_dim=settings.retriever_embedding_dim,
            sql_url=f"sqlite:///{settings.faiss_db_path.as_posix()}",
        )

    retriever = get_retriever(document_store, settings)

    for paper in papers:
        download_pdf(paper, settings.external_doc_dir)

    processed_paper = prepare_papers(settings)

    # Check for duplicates
    existing_documents = set(
        [doc.meta["name"] for doc in document_store.get_all_documents()]
    )
    new_documents = [
        doc for doc in processed_paper if doc.meta["name"] not in existing_documents
    ]

    document_store.write_documents(new_documents)
    document_store.update_embeddings(
        filters={"name": list(set([doc.meta["name"] for doc in new_documents]))},
        retriever=retriever,
        update_existing_embeddings=False,
    )
    document_store.save(
        index_path=settings.faiss_index_path, config_path=settings.faiss_config_path
    )

    return document_store, retriever
