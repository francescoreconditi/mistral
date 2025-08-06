# README.md

## 📋 Panoramica del Progetto

Questa è un'applicazione Mistral SQL Assistant che utilizza LlamaIndex e Streamlit per creare un'interfaccia interattiva di generazione di query SQL. Il sistema costruisce e interroga un indice vettoriale persistente da uno schema SQL per fornire assistenza SQL intelligente.

## 🏗️ Architettura

### Struttura del Progetto
```
src/
├── mistral/
│   ├── config.py          # Configurazioni centrali
│   ├── core/
│   │   ├── engine.py      # Query engine logic
│   │   └── indexer.py     # Index creation logic
│   ├── ui/
│   │   ├── app.py         # Streamlit app
│   │   └── components.py  # UI components
│   └── utils/
│       └── auth.py        # HuggingFace auth
tests/                     # Test suite
scripts/                   # Entry point scripts
data/
├── schema.sql            # SQL schema
└── db_index/             # Vector store
```

### Componenti Principali
- **src/mistral/ui/app.py**: Applicazione web Streamlit principale
- **src/mistral/core/engine.py**: Query engine con gestione LLM e embedding
- **src/mistral/core/indexer.py**: Creazione dell'indice vettoriale
- **src/mistral/config.py**: Configurazioni centralizzate
- **data/schema.sql**: Schema SQL come base di conoscenza
- **data/db_index/**: Storage persistente per il vector store

## 🔧 Stack Tecnologico

- **Frontend**: Framework web Streamlit
- **LLM**: Ollama con modello Mistral (basato su CPU)
- **Embeddings**: HuggingFace sentence-transformers/all-MiniLM-L6-v2 (accelerato GPU)
- **Vector Store**: LlamaIndex VectorStoreIndex con storage persistente
- **Package Manager**: uv (package manager Python moderno)

## ⚡ Comandi di Sviluppo

### 🔧 Configurazione Ambiente
```bash
# Installa dipendenze base
uv sync

# Installa dipendenze di sviluppo
uv sync --extra dev

# Copia e configura file di ambiente
cp .env.example .env
# Modifica .env con i tuoi token
```

### 🚀 Esecuzione dell'Applicazione
```bash
# Metodo 1: Usando gli script
uv run python scripts/run_app.py

# Metodo 2: Usando i console scripts
mistral-app

# Metodo 3: Streamlit diretto
uv run streamlit run src/mistral/ui/app.py
```

### 📊 Gestione Indice
```bash
# Metodo 1: Usando gli script
uv run python scripts/create_index.py

# Metodo 2: Usando i console scripts
mistral-create-index

# Metodo 3: Modulo diretto
uv run python -m mistral.core.indexer
```

### 📦 Gestione Pacchetti
```bash
uv add <package>          # Aggiunge dipendenza di produzione
uv add --dev <package>    # Aggiunge dipendenza di sviluppo
uv remove <package>       # Rimuove una dipendenza
uv lock                   # Aggiorna il lockfile
```

### 🧪 Testing e Quality
```bash
# Esegui test
uv run pytest

# Test con coverage
uv run pytest --cov=mistral --cov-report=html

# Linting e formatting
uv run ruff check src/
uv run ruff format src/

# Type checking
uv run mypy src/

# Pre-commit hooks
uv run pre-commit install
uv run pre-commit run --all-files
```

## ⚙️ Componenti Chiave

### 🔍 Query Engine (src/mistral/core/engine.py)
La funzione `load_query_engine()` inizializza:
- LLM Ollama/Mistral per la generazione di testo
- Embeddings HuggingFace con accelerazione GPU/CPU configurabile
- Caricamento dell'indice vettoriale persistente da `data/db_index/`
- Gestione centralizzata della configurazione e logging

### 🗂️ Creazione Indice (src/mistral/core/indexer.py)
- Legge il file di schema SQL da `data/schema.sql`
- Crea un indice vettoriale ricercabile
- Persiste su disco per caricamenti veloci successivi
- Configurazione centralizzata e gestione errori

### 🖥️ Interfaccia Utente (src/mistral/ui/)
- **app.py**: Logica principale dell'applicazione Streamlit
- **components.py**: Componenti UI modulari e riutilizzabili
- Generazione di query in tempo reale con timing delle risposte
- Estrazione del codice SQL e evidenziazione della sintassi
- Cronologia delle query con risposte espandibili
- Funzionalità di copia negli appunti per le risposte generate

### ⚙️ Configurazione (src/mistral/config.py)
- Configurazioni centralizzate con variabili d'ambiente
- Validazione automatica dei settings
- Gestione dei percorsi e delle directory
- Supporto per diversi ambienti (dev/prod)

## ⚠️ Note Importanti

### Prerequisiti
- **Python**: 3.10 o superiore
- **Ollama**: Deve essere installato separatamente con il modello Mistral
- **HuggingFace Token**: Richiesto per accedere ai modelli di embedding

### Configurazione
- Copia `.env.example` in `.env` e configura i tuoi token
- L'indice vettoriale viene costruito una volta e persiste tra le sessioni
- Configurazione centralizzata tramite variabili d'ambiente

### Prima Esecuzione
1. Installa le dipendenze: `uv sync --extra dev`
2. Configura il file `.env`
3. Crea l'indice: `mistral-create-index`
4. Avvia l'app: `mistral-app`

## 🚀 Requisiti Hardware

### GPU (Raccomandato)
Il modello di embedding è configurato per usare CUDA per prestazioni ottimali:
- Configura `DEVICE=cuda` nel file `.env`
- Assicurati che CUDA sia disponibile

### CPU (Alternativa)
Per sistemi senza GPU:
- Configura `DEVICE=cpu` nel file `.env`
- Le prestazioni saranno ridotte ma funzionali

## 🏗️ Sviluppo

### Struttura del Codice
- **src/**: Codice sorgente principale
- **tests/**: Test suite completa
- **scripts/**: Script di utilità
- **data/**: Dati e indici persistenti
