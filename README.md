# README.md

Questo file fornisce indicazioni a Claude Code (claude.ai/code) quando lavora con il codice in questo repository.

## 📋 Panoramica del Progetto

Questa è un'applicazione Mistral SQL Assistant che utilizza LlamaIndex e Streamlit per creare un'interfaccia interattiva di generazione di query SQL. Il sistema costruisce e interroga un indice vettoriale persistente da uno schema SQL per fornire assistenza SQL intelligente.

## 🏗️ Architettura

- **main.py**: Applicazione web Streamlit che fornisce l'interfaccia utente
- **engine.py**: Contiene il loader del query engine che inizializza i modelli LLM e di embedding
- **create_index.py**: Script eseguito una sola volta per costruire l'indice vettoriale dallo schema SQL
- **schema.sql**: File di schema SQL che serve come base di conoscenza per l'assistente
- **db_index/**: Directory di storage persistente per il vector store di LlamaIndex

## 🔧 Stack Tecnologico

- **Frontend**: Framework web Streamlit
- **LLM**: Ollama con modello Mistral (basato su CPU)
- **Embeddings**: HuggingFace sentence-transformers/all-MiniLM-L6-v2 (accelerato GPU)
- **Vector Store**: LlamaIndex VectorStoreIndex con storage persistente
- **Package Manager**: uv (package manager Python moderno)

## ⚡ Comandi di Sviluppo

### 🔧 Configurazione Ambiente
```bash
uv sync                    # Installa dipendenze e sincronizza ambiente
```

### 🚀 Esecuzione dell'Applicazione
```bash
uv run streamlit run main.py     # Avvia l'applicazione web Streamlit
```

### 📊 Gestione Indice
```bash
uv run python create_index.py    # Ricostruisce l'indice vettoriale da schema.sql
```

### 📦 Gestione Pacchetti
```bash
uv add <package>          # Aggiunge una nuova dipendenza
uv remove <package>       # Rimuove una dipendenza
uv lock                   # Aggiorna il lockfile
```

## ⚙️ Componenti Chiave

### 🔍 Query Engine (engine.py:15)
La funzione `load_query_engine()` inizializza:
- LLM Ollama/Mistral per la generazione di testo
- Embeddings HuggingFace con accelerazione GPU CUDA
- Caricamento dell'indice vettoriale persistente da `./db_index`

### 🗂️ Creazione Indice (create_index.py:23)
Legge il file di schema SQL e crea un indice vettoriale ricercabile che persiste su disco per caricamenti successivi veloci.

### 🖥️ Funzionalità UI (main.py)
- Generazione di query in tempo reale con timing delle risposte
- Estrazione del codice SQL e evidenziazione della sintassi
- Cronologia delle query con risposte espandibili
- Funzionalità di copia negli appunti per le risposte generate

## ⚠️ Note Importanti

- L'applicazione richiede GPU CUDA per prestazioni ottimali degli embeddings
- Ollama deve essere installato separatamente e il modello Mistral scaricato
- L'indice vettoriale viene costruito una volta e persiste tra le sessioni
- Il token HuggingFace viene caricato da variabili d'ambiente dal file .env

## 🚀 Requisiti GPU

Il modello di embedding è configurato per usare CUDA (`device="cuda"` in engine.py:22 e create_index.py:18). Assicurati che CUDA sia disponibile o modifica per usare la CPU se necessario.