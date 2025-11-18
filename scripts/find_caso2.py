# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Trovare dove si trova la sezione CASO 2 nel vector store
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def find_caso2():
    """Trova dove si trova CASO 2 nel vector store"""

    Config.validate()

    print("[INFO] Caricamento del vector store...")
    storage_context = StorageContext.from_defaults(
        persist_dir=str(Config.VECTOR_STORE_DIR)
    )
    index = load_index_from_storage(storage_context)

    # Cerca in tutti i documenti
    docstore = storage_context.docstore
    all_docs = docstore.docs

    print("[SEARCH] Ricerca CASO 2 in tutti i documenti...")

    for doc_id, doc in all_docs.items():
        if "CASO 2:" in doc.text or "VALORE MASSIMO/MINIMO" in doc.text:
            print(f"\n[OK] Trovato in documento: {doc_id[:50]}...")
            # Mostra un estratto
            idx = doc.text.find("CASO 2:")
            if idx == -1:
                idx = doc.text.find("VALORE MASSIMO/MINIMO")
            text = doc.text.encode('ascii', 'ignore').decode('ascii')
            print("\n--- CONTENUTO (primi 1000 caratteri) ---")
            print(text[max(0, idx-100):idx+1000])
            print("\n")

    # Ora testa il retrieval
    query = "la regione con il fatturato piu alto"
    print(f"\n{'='*80}")
    print(f"QUERY: '{query}'")
    print(f"{'='*80}")

    retriever = index.as_retriever(similarity_top_k=30)
    nodes = retriever.retrieve(query)

    for i, node in enumerate(nodes, 1):
        if "CASO 2" in node.text:
            print(f"\n[OK] CASO 2 trovato al NODO {i} (Score: {node.score:.4f})")
            break
    else:
        print("\n[ERROR] CASO 2 NON trovato nei top 30 nodi")

if __name__ == "__main__":
    try:
        find_caso2()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
