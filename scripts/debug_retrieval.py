# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Analizzare cosa recupera il vector store per la query "Fatturato per regione"
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def debug_query_retrieval():
    """Debug: cosa recupera il vector store per 'Fatturato per regione'"""

    Config.validate()

    print("[INFO] Caricamento del vector store...")
    storage_context = StorageContext.from_defaults(
        persist_dir=str(Config.VECTOR_STORE_DIR)
    )
    index = load_index_from_storage(storage_context)
    print("[OK] Vector store caricato\n")

    # La query dell'utente
    user_query = "Fatturato per regione"

    print("=" * 80)
    print(f"QUERY UTENTE: '{user_query}'")
    print("=" * 80)

    # Testa con diversi valori di similarity_top_k
    for top_k in [2, 5, 10]:
        print(f"\n[TEST] Retrieval con similarity_top_k={top_k}")
        print("-" * 80)

        retriever = index.as_retriever(similarity_top_k=top_k)
        nodes = retriever.retrieve(user_query)

        if not nodes:
            print("[ERROR] Nessun nodo recuperato!")
            continue

        print(f"[OK] Recuperati {len(nodes)} nodi\n")

        for i, node in enumerate(nodes, 1):
            print(f"--- NODO {i} (Score: {node.score:.4f}) ---")
            print(node.text[:800])  # Primi 800 caratteri
            print("\n")

    # Verifica se le istruzioni sulle regioni sono presenti
    print("\n" + "=" * 80)
    print("[SEARCH] Verifica presenza informazioni su tab_regioni")
    print("=" * 80)

    docstore = storage_context.docstore
    all_docs = docstore.docs

    search_terms = ["tab_regioni", "regioni", "localita.s_tab_regioni"]

    for term in search_terms:
        print(f"\n[SEARCH] Cercando '{term}'...")
        found_count = 0
        for doc_id, doc in all_docs.items():
            if term.lower() in doc.text.lower():
                found_count += 1
                if found_count <= 2:  # Mostra solo i primi 2 match
                    print(f"  TROVATO in {doc_id[:40]}...")
                    # Trova il contesto intorno al termine
                    idx = doc.text.lower().find(term.lower())
                    start = max(0, idx - 100)
                    end = min(len(doc.text), idx + 200)
                    context = doc.text[start:end].replace("\n", " ")
                    print(f"  Contesto: ...{context}...")
        print(f"  Totale occorrenze: {found_count}")

if __name__ == "__main__":
    try:
        debug_query_retrieval()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
