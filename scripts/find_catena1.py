# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Trovare in quale nodo si trova la CATENA 1 (Documento -> Regione)
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def find_catena1():
    """Trova la CATENA 1 nel vector store"""

    Config.validate()

    print("[INFO] Caricamento del vector store...")
    storage_context = StorageContext.from_defaults(
        persist_dir=str(Config.VECTOR_STORE_DIR)
    )
    index = load_index_from_storage(storage_context)

    query = "Fatturato per regione"

    print("=" * 80)
    print(f"QUERY: '{query}'")
    print("=" * 80)

    # Test con top_k alto per vedere tutti i nodi
    print("\n[TEST] Retrieval con top_k=15")
    print("-" * 80)

    retriever = index.as_retriever(similarity_top_k=15)
    nodes = retriever.retrieve(query)

    for i, node in enumerate(nodes, 1):
        if "CATENA 1" in node.text or "Documento -> Regione" in node.text:
            print(f"\n=== TROVATO! NODO {i} (Score: {node.score:.4f}) ===")
            text = node.text.encode('ascii', 'ignore').decode('ascii')
            print(text[:1500])
            print("\n")
            break
    else:
        print("\n[ERROR] CATENA 1 NON trovata nei primi 15 nodi!")

    # Cerca anche CASO 1
    print("\n" + "=" * 80)
    print("RICERCA CASO 1: AGGREGAZIONE SEMPLICE")
    print("=" * 80)

    for i, node in enumerate(nodes, 1):
        if "CASO 1" in node.text or "AGGREGAZIONE SEMPLICE" in node.text:
            print(f"\n=== TROVATO! NODO {i} (Score: {node.score:.4f}) ===")
            text = node.text.encode('ascii', 'ignore').decode('ascii')
            print(text[:1500])
            print("\n")
            break
    else:
        print("\n[ERROR] CASO 1 NON trovato nei primi 15 nodi!")

if __name__ == "__main__":
    try:
        find_catena1()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
