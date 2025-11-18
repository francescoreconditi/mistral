# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Verificare se la sezione "ERRORE COMUNE" viene recuperata
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def test_errore_comune():
    """Verifica se la sezione ERRORE COMUNE viene recuperata"""

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

    # Test con top_k=15 (come configurato in engine.py)
    retriever = index.as_retriever(similarity_top_k=15)
    nodes = retriever.retrieve(query)

    # Cerca la sezione "ERRORE COMUNE"
    for i, node in enumerate(nodes, 1):
        if "ERRORE COMUNE" in node.text or "TABELLE MANCANTI NELLA FROM" in node.text:
            print(f"\n[OK] Sezione 'ERRORE COMUNE' trovata al NODO {i}")
            print(f"Score: {node.score:.4f}\n")
            # Mostra l'inizio del contenuto
            text = node.text.encode('ascii', 'ignore').decode('ascii')
            print(text[:800])
            print("\n")
            return

    print("\n[ERROR] Sezione 'ERRORE COMUNE' NON trovata nei top 15 nodi")

    # Mostra tutti i nodi per debug
    print("\n" + "=" * 80)
    print("TUTTI I NODI RECUPERATI:")
    print("=" * 80)
    for i, node in enumerate(nodes, 1):
        preview = node.text[:100].encode('ascii', 'ignore').decode('ascii').replace("\n", " ")
        print(f"{i}. Score {node.score:.4f}: {preview}...")

if __name__ == "__main__":
    try:
        test_errore_comune()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
