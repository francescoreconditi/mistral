# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Test specifico per query "Fatturato per regione"
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def test_fatturato_regione():
    """Test specifico per 'Fatturato per regione'"""

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

    # Test con top_k=3
    print("\n[TEST] Retrieval con top_k=3")
    print("-" * 80)

    retriever = index.as_retriever(similarity_top_k=3)
    nodes = retriever.retrieve(query)

    for i, node in enumerate(nodes, 1):
        print(f"\n=== NODO {i} (Score: {node.score:.4f}) ===")
        # Mostra tutto il contenuto (senza limiti)
        text = node.text.encode('ascii', 'ignore').decode('ascii')
        print(text[:1000])
        print("\n")

    # Verifica se le istruzioni chiave sono presenti
    print("\n" + "=" * 80)
    print("[VERIFICA] Presenza istruzioni chiave nei top 3 nodi")
    print("=" * 80)

    keywords = [
        "CASO 1: AGGREGAZIONE SEMPLICE",
        "Fatturato per regione",
        "tab_regioni",
        "CATENA 1: Documento -> Regione",
        "GROUP BY"
    ]

    for keyword in keywords:
        found = False
        for i, node in enumerate(nodes, 1):
            if keyword.lower() in node.text.lower():
                print(f"[OK] '{keyword}' trovato nel NODO {i}")
                found = True
                break
        if not found:
            print(f"[ERROR] '{keyword}' NON trovato nei top 3 nodi")

if __name__ == "__main__":
    try:
        test_fatturato_regione()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
