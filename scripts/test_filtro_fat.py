# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Verificare se la regola del filtro FAT viene recuperata
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def test_filtro_fat():
    """Verifica se la regola del filtro FAT viene recuperata per 'Fatturato per regione'"""

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

    # Cerca le parole chiave della regola FAT
    keywords = [
        "j_cfg_doc_rag",
        "cod_rag_doc = 'FAT'",
        "FILTRO FATTURATO",
        "REGOLA CRITICA: FILTRO"
    ]

    print("\n[VERIFICA] Presenza regola filtro FAT nei top 15 nodi:")
    print("-" * 80)

    for keyword in keywords:
        found_at = []
        for i, node in enumerate(nodes, 1):
            if keyword.lower() in node.text.lower():
                found_at.append(i)

        if found_at:
            print(f"[OK] '{keyword}' trovato nei nodi: {found_at[:3]}")  # Mostra primi 3
        else:
            print(f"[ERROR] '{keyword}' NON trovato")

    # Mostra i primi 3 nodi per vedere cosa viene recuperato
    print("\n" + "=" * 80)
    print("PRIMI 3 NODI RECUPERATI:")
    print("=" * 80)

    for i in range(min(3, len(nodes))):
        node = nodes[i]
        print(f"\n--- NODO {i+1} (Score: {node.score:.4f}) ---")
        text = node.text.encode('ascii', 'ignore').decode('ascii')
        print(text[:500])
        print("...\n")

if __name__ == "__main__":
    try:
        test_filtro_fat()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
