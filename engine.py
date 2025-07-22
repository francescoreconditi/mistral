from huggingface_hub import login

login(token=None)

from langchain_community.llms import Ollama
from llama_index import (
    ServiceContext,
    StorageContext,
    load_index_from_storage,
)
from llama_index.embeddings import HuggingFaceEmbedding
from llama_index.llms.langchain import LangChainLLM


def load_query_engine():
    # Ricrea il tuo service context per la sessione attuale
    llm = LangChainLLM(llm=Ollama(model="mistral"))
    embed_model = HuggingFaceEmbedding(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )
    service_context = ServiceContext.from_defaults(llm=llm, embed_model=embed_model)

    # Carica l’indice già esistente passando il context
    storage_context = StorageContext.from_defaults(persist_dir="./db_index")
    index = load_index_from_storage(
        storage_context=storage_context, service_context=service_context
    )

    return index.as_query_engine()
