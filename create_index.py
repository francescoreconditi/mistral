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
# Assicurati che il file schema.sql sia nella stessa cartella di questo script
documents = SimpleDirectoryReader(input_files=["schema.sql"]).load_data()

# Crea indice
index = VectorStoreIndex.from_documents(documents, service_context=service_context)

# Salva su disco
index.storage_context.persist(persist_dir="./db_index")

print("✅ Indice creato e salvato in ./db_index")