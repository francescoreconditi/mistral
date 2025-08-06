import os
from dotenv import load_dotenv
from huggingface_hub import login

# Carica le variabili d'ambiente dal file .env
load_dotenv()

# Effettua il login con il token dalle variabili d'ambiente
hf_token = os.getenv("HUGGINGFACE_TOKEN")
if hf_token:
    login(token=hf_token)
else:
    raise ValueError("HUGGINGFACE_TOKEN non trovato nel file .env")

from langchain_community.llms import Ollama
from llama_index import (
    ServiceContext,
    StorageContext,
    load_index_from_storage,
)
from llama_index.embeddings import HuggingFaceEmbedding
from llama_index.llms.langchain import LangChainLLM


def load_query_engine():
    # Inizializza LLM (nota: Ollama su Windows usa CPU)
    llm = LangChainLLM(llm=Ollama(model="mistral"))

    # ⚡️ Usa la GPU per l'embedding model
    embed_model = HuggingFaceEmbedding(
        model_name="sentence-transformers/all-MiniLM-L6-v2",
        device="cuda",  # <<--- ATTIVAZIONE GPU
    )

    # Crea il ServiceContext ottimizzato
    service_context = ServiceContext.from_defaults(llm=llm, embed_model=embed_model)

    # Carica l'indice persistente
    storage_context = StorageContext.from_defaults(persist_dir="./db_index")
    index = load_index_from_storage(
        storage_context=storage_context, service_context=service_context
    )

    return index.as_query_engine()