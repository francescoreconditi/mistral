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
