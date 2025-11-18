# ============================================
# FILE DI TEST/DEBUG - NON PER PRODUZIONE
# Creato da: Claude Code
# Data: 2025-11-17
# Scopo: Verificare se le istruzioni dal schema.sql (riga 755+) sono indicizzate nel vector store
# ============================================

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from mistral.config import Config
from llama_index.core import StorageContext, load_index_from_storage

def test_vector_store_content():
    """Verifica se le istruzioni dalla riga 755+ sono nel vector store"""

    # Validate config
    Config.validate()

    print("[INFO] Caricamento del vector store...")
    storage_context = StorageContext.from_defaults(
        persist_dir=str(Config.VECTOR_STORE_DIR)
    )
    index = load_index_from_storage(storage_context)

    print("[OK] Vector store caricato con successo!\n")

    # Test queries per verificare se le istruzioni sono presenti
    test_queries = [
        "JOIN_MAP_EXTENDED relazioni documentali",
        "regole OUTER JOIN Informix legacy",
        "CASE WHEN tp_doc_kon storno importi",
        "GROUP BY numero posizionale Informix",
        "tabelle temporanee INTO TEMP WITH NO LOG",
        "classifiche TOP N articoli più venduti",
        "validità referenziale uso tabelle FROM",
        "annidamento OUTER JOIN cascata nullable"
    ]

    print("=" * 80)
    print("TEST: Recupero delle istruzioni dal vector store")
    print("=" * 80)

    for i, query in enumerate(test_queries, 1):
        print(f"\n[Test {i}/{len(test_queries)}] Query: '{query}'")
        print("-" * 80)

        # Retrieve context (senza generare SQL)
        retriever = index.as_retriever(similarity_top_k=2)
        nodes = retriever.retrieve(query)

        if nodes:
            print(f"[OK] Trovati {len(nodes)} nodi rilevanti")
            for j, node in enumerate(nodes, 1):
                content_preview = node.text[:200].replace("\n", " ")
                print(f"   Nodo {j}: {content_preview}...")
                print(f"   Score: {node.score:.4f}")
        else:
            print("[ERROR] Nessun nodo trovato")

    print("\n" + "=" * 80)
    print("[STATS] Statistiche del vector store")
    print("=" * 80)

    # Get docstore info
    docstore = storage_context.docstore
    all_docs = docstore.docs

    print(f"Numero totale di documenti indicizzati: {len(all_docs)}")
    print(f"\nPrimi 3 documenti (preview):")
    for i, (doc_id, doc) in enumerate(list(all_docs.items())[:3], 1):
        content_preview = doc.text[:150].replace("\n", " ")
        print(f"{i}. ID: {doc_id[:50]}...")
        print(f"   Contenuto: {content_preview}...")

    print("\n" + "=" * 80)
    print("[SEARCH] Ricerca specifica delle sezioni di istruzioni")
    print("=" * 80)

    # Verifica presenza di sezioni specifiche
    sections_to_check = [
        "JOIN_MAP_EXTENDED",
        "JOIN_RULES_ENFORCED",
        "VALIDITÀ REFERENZIALE E USO DELLE TABELLE",
        "REGOLE DI GENERAZIONE QUERY INFORMIX SQL",
        "CLASSIFICHE TOP N"
    ]

    for section in sections_to_check:
        found = False
        for doc_id, doc in all_docs.items():
            if section in doc.text:
                found = True
                print(f"[OK] Sezione '{section}' TROVATA nel documento {doc_id[:50]}...")
                break
        if not found:
            print(f"[ERROR] Sezione '{section}' NON TROVATA")

if __name__ == "__main__":
    try:
        test_vector_store_content()
    except Exception as e:
        print(f"[ERROR] Errore durante il test: {e}")
        import traceback
        traceback.print_exc()
