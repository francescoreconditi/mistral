CREATE TABLE clienti (
  id INT PRIMARY KEY,
  nome VARCHAR(100),
  email VARCHAR(100)
);

CREATE TABLE ordini (
  id INT PRIMARY KEY,
  cliente_id INT,
  data DATE,
  totale NUMERIC,
  FOREIGN KEY (cliente_id) REFERENCES clienti(id)
);

-- ISTRUZIONI PER L'ASSISTENTE SQL:
-- Quando l'utente specifica periodi temporali (es. "ultimi 30 giorni", "questo mese", "dal 2024"), 
-- utilizzare SEMPRE il campo 'ordini.data' per filtrare temporalmente.
-- Esempi di filtri temporali automatici:
-- - "ultimi 30 giorni" -> WHERE ordini.data >= CURRENT_DATE - INTERVAL '30 days'
-- - "questo mese" -> WHERE EXTRACT(MONTH FROM ordini.data) = EXTRACT(MONTH FROM CURRENT_DATE)
-- - "anno 2024" -> WHERE EXTRACT(YEAR FROM ordini.data) = 2024
