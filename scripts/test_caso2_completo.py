# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Verificare se il CASO 2 completo e la regola anti-abbreviazioni vengono recuperati
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def test_caso2_completo():
    """Verifica CASO 2 completo per 'la regione con il fatturato piu alto'"""

    Config.validate()

    print("[INFO] Caricamento del vector store...")
    storage_context = StorageContext.from_defaults(
        persist_dir=str(Config.VECTOR_STORE_DIR)
    )
    index = load_index_from_storage(storage_context)

    query = "la regione con il fatturato piu alto"

    print("=" * 80)
    print(f"QUERY: '{query}'")
    print("=" * 80)

    # Test con top_k=15 (come configurato in engine.py)
    retriever = index.as_retriever(similarity_top_k=15)
    nodes = retriever.retrieve(query)

    # Cerca le parole chiave
    keywords = [
        "CASO 2:",
        "La regione con il fatturato piu alto",
        "INTO TEMP fat_reg",
        "j_cfg_doc_rag",
        "cod_rag_doc = 'FAT'",
        "NON ABBREVIARE MAI",
        'ERRORE GRAVISSIMO',
        "SELECT ... GROUP BY ... INTO TEMP"
    ]

    print("\n[VERIFICA] Presenza istruzioni CASO 2 e anti-abbreviazioni:")
    print("-" * 80)

    for keyword in keywords:
        found_at = []
        for i, node in enumerate(nodes, 1):
            if keyword.lower() in node.text.lower():
                found_at.append(i)

        if found_at:
            positions = ', '.join(map(str, found_at[:5]))
            print(f"[OK] '{keyword}' trovato nei nodi: {positions}")
        else:
            print(f"[ERROR] '{keyword}' NON trovato")

    # Mostra dove si trova il CASO 2
    print("\n" + "=" * 80)
    print("RICERCA CASO 2 COMPLETO:")
    print("=" * 80)

    for i, node in enumerate(nodes, 1):
        if "CASO 2:" in node.text and "La regione con il fatturato" in node.text:
            print(f"\n[OK] CASO 2 completo trovato al NODO {i} (Score: {node.score:.4f})")
            text = node.text.encode('ascii', 'ignore').decode('ascii')
            # Mostra l'esempio completo
            if "Prima query (aggregazione in TEMP):" in text:
                idx = text.find("Prima query (aggregazione in TEMP):")
                print("\n--- ESEMPIO COMPLETO ---")
                print(text[idx:idx+1200])
            break
    else:
        print("\n[ERROR] CASO 2 completo NON trovato!")

if __name__ == "__main__":
    try:
        test_caso2_completo()
    except Exception as e:
        print(f"[ERROR] Errore: {e}")
        import traceback
        traceback.print_exc()
