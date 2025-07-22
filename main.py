import streamlit as st

from engine import load_query_engine

st.set_page_config(page_title="Assistente SQL", page_icon="🧠")
st.title("🧠 Assistente SQL con indice persistente")

# Carica query engine
if "query_engine" not in st.session_state:
    st.session_state.query_engine = load_query_engine()

if "history" not in st.session_state:
    st.session_state.history = []

user_query = st.text_area("Scrivi una richiesta:", height=100)

if st.button("Genera query") and user_query.strip():
    with st.spinner("Generazione in corso..."):
        response = st.session_state.query_engine.query(user_query)
        st.session_state.history.append(
            {"domanda": user_query, "risposta": str(response)}
        )

# Cronologia
if st.session_state.history:
    st.subheader("📜 Cronologia")
    for item in reversed(st.session_state.history):
        st.markdown(f"**Domanda:** {item['domanda']}")
        st.code(item["risposta"], language="sql")
