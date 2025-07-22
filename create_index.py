from huggingface_hub import login

login(token="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")

from langchain_community.llms import Ollama
from llama_index import (
    ServiceContext,
    SimpleDirectoryReader,
    VectorStoreIndex,
)
from llama_index.embeddings import HuggingFaceEmbedding
from llama_index.llms.langchain import LangChainLLM

# Inizializza componenti
llm = LangChainLLM(llm=Ollama(model="mistral"))
embed_model = HuggingFaceEmbedding(
    model_name="sentence-transformers/all-MiniLM-L6-v2",
    device="cuda",  # Usa la GPU
)
service_context = ServiceContext.from_defaults(llm=llm, embed_model=embed_model)

# Carica schema
documents = SimpleDirectoryReader(input_files=["schema.sql"]).load_data()

# Crea indice
index = VectorStoreIndex.from_documents(documents, service_context=service_context)

# Salva su disco
index.storage_context.persist(persist_dir="./db_index")

print("✅ Indice creato e salvato in ./db_index")
