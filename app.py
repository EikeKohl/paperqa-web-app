import logging
import shutil

import streamlit as st

from paperqa import QASettings, get_qa_pipeline, update_documentstore

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler("app.log"), logging.StreamHandler()],
)


def side_bar():
    st.sidebar.header("Settings")

    st.session_state.temperature = st.sidebar.slider(
        "Temperature",
        min_value=0.0,
        max_value=1.0,
        value=0.2,
    )

    st.session_state.generator_max_tokens = st.sidebar.slider(
        "Max Tokens Answer", min_value=100, max_value=2000, step=100, value=500
    )

    st.session_state.num_contexts = st.sidebar.slider(
        "Number of Context Matches",
        min_value=1,
        max_value=10,
        step=1,
        value=5,
    )

    st.sidebar.header("Context Matches")

    # Create buttons for iterating through contexts
    if st.sidebar.button("Previous"):
        st.session_state.current_index = min(
            (st.session_state.current_index - 1) % st.session_state.num_contexts, 0
        )

    if st.sidebar.button("Next"):
        st.session_state.current_index = (
            st.session_state.current_index + 1
        ) % st.session_state.num_contexts

    if st.session_state.get("context"):
        st.sidebar.markdown(
            f"""**Source:** {st.session_state.context[st.session_state.current_index][0]}
        \n\n**Score:** {st.session_state.context[st.session_state.current_index][1]}
        \n\n**Text:** {st.session_state.context[st.session_state.current_index][2]}"""
        )


def app(settings):
    st.set_page_config(page_title="PaperQA", layout="wide")

    st.title("PaperQA")

    side_bar()

    settings.update_from_session_state(st.session_state)

    params = {
        "Retriever": {"top_k": st.session_state.num_contexts},
        "Generator": {"top_k": 1},
    }

    # Create user input text area
    papers = st.text_area(
        "Papers to query (separated by ',' in case of multiple papers)",
        key="papers",
        height=100,
    )
    left, right = st.columns(2)

    with left:
        if st.button("Add papers to database"):
            with st.spinner("✨ Updating the database..."):
                (
                    st.session_state.document_store,
                    st.session_state.retriever,
                ) = update_documentstore(papers=papers.split(","), settings=settings)

    with right:
        if st.session_state.get("document_store"):
            if st.button("Reset database"):
                st.session_state.document_store.delete_documents()
                settings.faiss_index_path.unlink()
                settings.faiss_config_path.unlink()
                settings.faiss_db_path.unlink()
                shutil.rmtree(settings.external_doc_dir.as_posix())

    question = st.text_area(
        "What would you like to know about the paper?",
        key="query",
        height=100,
    )

    if st.button("Query Paper"):
        if not st.session_state.get("retriever"):
            st.warning("Please add papers to the database first!")

        with st.spinner("🕵️ Analyzing papers..."):
            pipeline = get_qa_pipeline(
                settings=settings, retriever=st.session_state.retriever
            )
            st.session_state.current_index = 0
            model_answer = pipeline.run(query=question, params=params)
            context_docs = model_answer["documents"]
            st.session_state.context = tuple(
                zip(
                    [doc.meta["name"] for doc in context_docs],
                    [doc.score for doc in context_docs],
                    [doc.content for doc in context_docs],
                )
            )
            st.session_state.answer = model_answer["answers"][0].answer
            st.experimental_rerun()

    st.session_state.answer = st.text_area(
        "Answer:",
        st.session_state.get("answer", " "),
        height=300,
    )


if __name__ == "__main__":
    initial_settings = QASettings.init_settings("src/config.yaml")
    app(initial_settings)
