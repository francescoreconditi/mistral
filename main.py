import html
import re
import time

import streamlit as st

from engine import load_query_engine

# ---------- STILE PERSONALIZZATO ----------
st.markdown(
    """
    <style>
    .copy-button {
        background-color: #f0f2f6;
        border: 1px solid #ccc;
        padding: 6px 10px;
        border-radius: 4px;
        font-size: 0.9rem;
        cursor: pointer;
        margin-top: 10px;
    }

    .copy-button:hover {
        background-color: #e0e0e0;
    }
    </style>
""",
    unsafe_allow_html=True,
)

# ---------- CONFIGURAZIONE PAGINA ----------
st.set_page_config(page_title="Assistente SQL", page_icon="🧠")
st.title("🧠 Assistente SQL con indice persistente")

# ---------- CARICAMENTO QUERY ENGINE ----------
if "query_engine" not in st.session_state:
    st.session_state.query_engine = load_query_engine()

if "history" not in st.session_state:
    st.session_state.history = []

# ---------- INPUT UTENTE ----------
user_query = st.text_area("Scrivi una richiesta:", height=100)

if st.button("Genera query") and user_query.strip():
    with st.spinner("Generazione in corso..."):
        start_time = time.time()
        response = st.session_state.query_engine.query(user_query)
        elapsed = time.time() - start_time

        st.session_state.history.append(
            {
                "domanda": user_query,
                "risposta": str(response),
                "tempo": f"{elapsed:.2f} secondi",
            }
        )
        st.success(f"Risposta generata in {elapsed:.2f} secondi ✅")

# ---------- CRONOLOGIA ----------
if st.session_state.history:
    st.subheader("📜 Cronologia")

    for i, item in enumerate(reversed(st.session_state.history)):
        with st.expander(f"❓ Domanda: {item['domanda']}", expanded=False):
            st.markdown(f"⏱️ **Tempo di risposta:** `{item['tempo']}`")

            # Mostra la risposta con word wrap completo
            st.text_area(
                "Risposta:", value=item["risposta"], height=200, key=f"txt_{i}"
            )

            # Estrai eventuale codice SQL da blocchi ```sql ... ```
            match = re.search(r"```sql(.*?)```", item["risposta"], re.DOTALL)
            if match:
                sql_code = match.group(1).strip()
                st.code(sql_code, language="sql")

            # Pulizia HTML + rimozione blocchi markdown dalla risposta per la copia
            cleaned = re.sub(r"```.*?```", "", item["risposta"], flags=re.DOTALL)
            escaped = html.escape(cleaned).replace("`", "\\`")

            # Bottone di copia
            st.markdown(
                f"""
                <button class="copy-button" onclick="navigator.clipboard.writeText(`{escaped}`)">
                    📋 Copia la risposta
                </button>
            """,
                unsafe_allow_html=True,
            )
