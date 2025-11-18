/*
==================== DIZIONARIO TABELLE - NOMI ESATTI ====================

IMPORTANTE: Usa SOLO i nomi di tabella elencati qui. NON inventare varianti.

TABELLE PRINCIPALI:
  - cfg_doc               (NON cfg_documento, NON config_doc)
  - doc_t                 (testata documenti)
  - doc_r                 (righe documento generiche)
  - doc_r_art             (righe documento articoli)
  - doc_r_lotti           (lotti su righe)
  - j_cfg_doc_kon         (configurazione contabile documenti)
  - j_cfg_doc_rag         (raggruppamenti documenti)
  - j_doc_t_tot           (totalizzatori testata)
  - j_doc_stato           (stati documenti)
  - j_doc_iva             (righe IVA)

ANAGRAFICHE:
  - sog                   (soggetti/clienti - NON soggetto, NON cliente)
  - j_sog_tipo            (join soggetto-tipo soggetto)
  - tab_tp_sog            (tipi soggetto)

ARTICOLI:
  - art                   (articoli - NON articolo, NON articoli)
  - j_art_cls             (join articolo-classe)
  - sa_tpcls_sf           (classi articoli)

LOCALIZZAZIONE:
  - localita              (località - NON localita_table, NON comuni)
  - tab_regioni           (regioni - NON cfg_regione, NON regione, NON cfg_regioni)
  - tab_comuni            (comuni)
  - tab_ripartiz_geo      (ripartizioni geografiche)

MAGAZZINO:
  - magaz                 (magazzini - NON magazzino)
  - lotto                 (lotti)

PAGAMENTI:
  - cond_pag              (condizioni pagamento)
  - partite               (partite)
  - scadenze              (scadenze)

CONFIGURAZIONI:
  - ese_stag              (esercizi/stagioni)

Se devi usare una tabella, verifica SEMPRE che esista in questo elenco.

==================== REGOLA CRITICA: FILTRO FATTURATO ====================

IMPORTANTE - Quando la richiesta menziona "FATTURATO" o "FATTURA" o "FATTURE":

1. DEVI includere la tabella j_cfg_doc_rag nella clausola FROM
2. DEVI aggiungere queste condizioni nella clausola WHERE:
   - cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc
   - j_cfg_doc_rag.cod_rag_doc = 'FAT'

Questo filtro seleziona SOLO i documenti che appartengono al raggruppamento 'FAT' (Fatture).

Parole chiave che attivano questa regola:
  - "fatturato" "fattura" "fatture"
  - "vendite fatturate" "importo fatturato"
  - "documenti di tipo fattura"

NOTA: Se la query non menziona esplicitamente "fatturato/fattura", NON aggiungere questo filtro.

==================== CASI D'USO COMUNI: AGGREGAZIONE vs MAX/MIN ====================

REGOLA FONDAMENTALE: Distingui tra richieste di AGGREGAZIONE SEMPLICE e richieste di VALORE MASSIMO/MINIMO

**CASO 1: AGGREGAZIONE SEMPLICE (GROUP BY)**
Richieste del tipo (TUTTE richiedono GROUP BY, NON MAX/MIN):
  - "Fatturato per regione" "Vendite per regione" "Importo per regione"
  - "Fatturato per cliente" "Vendite per cliente" "Importo per soggetto"
  - "Fatturato per articolo" "Vendite per prodotto" "Importo per articolo"
  - "Fatturato per mese" "Vendite per periodo" "Documenti per data"
  - "Fatturato per località" "Vendite per città" "Importo per comune"
  - "Quantità per magazzino" "Pezzi per deposito"

Parole chiave che indicano AGGREGAZIONE SEMPLICE:
  - "per" (es: "fatturato PER regione")
  - "raggruppato per" "suddiviso per" "dettaglio per" "ripartito per"
  - "diviso per" "separato per" "distribuito per"

Pattern: **GROUP BY** con TUTTE le righe (NON usare MAX, MIN, FIRST, INTO TEMP)

Esempio: "Fatturato per regione"
SELECT
  tab_regioni.cod_regione,
  tab_regioni.des_regione,
  SUM(
    CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
      THEN -1 * j_doc_t_tot.imp_totale
      ELSE j_doc_t_tot.imp_totale
    END
  ) AS fatturato_totale
FROM doc_t, j_sog_tipo, sog, cfg_doc, j_cfg_doc_kon, j_cfg_doc_rag, j_doc_t_tot,
     OUTER (localita, OUTER tab_regioni)
WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
  AND j_sog_tipo.s_sog = sog.s_sog
  AND sog.s_localita_ind = localita.s_localita
  AND localita.s_tab_regioni = tab_regioni.s_tab_regioni
  AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc
  AND j_cfg_doc_rag.cod_rag_doc = 'FAT'
  AND doc_t.s_doc_t = j_doc_t_tot.s_doc_t
GROUP BY 1, 2
ORDER BY 3 DESC;

**CASO 2: VALORE MASSIMO/MINIMO (MAX/MIN con INTO TEMP)**
Richieste del tipo:
  - "Regione CON IL MAGGIOR fatturato" "Regione con il fatturato più alto"
  - "Cliente CHE HA SPESO DI PIÙ"
  - "Articolo PIÙ VENDUTO"
  - "Mese CON IL MINOR incasso"

Parole chiave: "con il maggior", "con il minor", "che ha speso di più", "più venduto", "meno venduto", "con il fatturato più alto"
Pattern: **INTO TEMP** + **SELECT MAX/MIN** con UNA SOLA riga

ATTENZIONE: Se la richiesta menziona "FATTURATO" o "FATTURA", DEVI includere anche qui:
  - j_cfg_doc_rag nella FROM
  - cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc nella WHERE
  - j_cfg_doc_rag.cod_rag_doc = 'FAT' nella WHERE

Esempio COMPLETO: "La regione con il fatturato più alto"

Prima query (aggregazione in TEMP):
SELECT
  tab_regioni.cod_regione,
  tab_regioni.des_regione,
  SUM(
    CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
      THEN -1 * j_doc_t_tot.imp_totale
      ELSE j_doc_t_tot.imp_totale
    END
  ) AS fatturato
FROM doc_t, j_sog_tipo, sog, cfg_doc, j_cfg_doc_kon, j_cfg_doc_rag, j_doc_t_tot,
     OUTER (localita, OUTER tab_regioni)
WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
  AND j_sog_tipo.s_sog = sog.s_sog
  AND sog.s_localita_ind = localita.s_localita
  AND localita.s_tab_regioni = tab_regioni.s_tab_regioni
  AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc
  AND j_cfg_doc_rag.cod_rag_doc = 'FAT'
  AND doc_t.s_doc_t = j_doc_t_tot.s_doc_t
GROUP BY 1, 2
INTO TEMP fat_reg_1051 WITH NO LOG;

Seconda query (estrazione MAX):
SELECT
  (SELECT cod_regione FROM fat_reg_1051 WHERE fatturato = (SELECT MAX(fatturato) FROM fat_reg_1051)) AS cod_max,
  (SELECT des_regione FROM fat_reg_1051 WHERE fatturato = (SELECT MAX(fatturato) FROM fat_reg_1051)) AS des_max,
  (SELECT MAX(fatturato) FROM fat_reg_1051) AS valore_max
FROM systables WHERE tabid = 1;

==================== CATENE DI JOIN FREQUENTI ====================

**CATENA 1: Documento -> Regione**
Path completo: doc_t -> j_sog_tipo -> sog -> localita -> tab_regioni
Usa questa catena per: fatturato per regione, vendite per regione, clienti per regione

FROM doc_t, j_sog_tipo, sog, OUTER (localita, OUTER tab_regioni)
WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
  AND j_sog_tipo.s_sog = sog.s_sog
  AND sog.s_localita_ind = localita.s_localita
  AND localita.s_tab_regioni = tab_regioni.s_tab_regioni

Nota: localita e tab_regioni sono OUTER perché nullable.

**CATENA 2: Documento -> Articolo -> Classe**
Path completo: doc_t -> doc_r -> doc_r_art -> art -> j_art_cls -> sa_tpcls_sf
Usa questa catena per: fatturato per articolo, vendite per classe, quantità per prodotto

FROM doc_t, doc_r, doc_r_art, art, OUTER (j_art_cls, OUTER sa_tpcls_sf)
WHERE doc_t.s_doc_t = doc_r.s_doc_t
  AND doc_r.s_doc_r = doc_r_art.s_doc_r
  AND doc_r_art.s_art = art.s_art
  AND art.s_art = j_art_cls.s_art
  AND j_art_cls.s_j_tab_tpcls_lv = sa_tpcls_sf.s_tpcls_lv

**CATENA 3: Documento -> Importi (con storno)**
Quando servono importi, SEMPRE includere j_cfg_doc_kon:
Usa questa catena per: fatturato totale, importo vendite, calcolo totali, somma importi

FROM doc_t, cfg_doc, j_cfg_doc_kon, j_doc_t_tot
WHERE doc_t.s_cfg_doc = cfg_doc.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc
  AND doc_t.s_doc_t = j_doc_t_tot.s_doc_t

E usare CASE WHEN:
CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
  THEN -1 * j_doc_t_tot.imp_totale
  ELSE j_doc_t_tot.imp_totale
END

ATTENZIONE - Se la richiesta menziona "FATTURATO" o "FATTURA":
Aggiungi alla FROM: j_cfg_doc_rag
Aggiungi alla WHERE:
  AND cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc
  AND j_cfg_doc_rag.cod_rag_doc = 'FAT'

**CATENA 4: Documento -> Cliente -> Località**
Path completo: doc_t -> j_sog_tipo -> sog -> localita
Usa questa catena per: fatturato per cliente, vendite per località, documenti per città

FROM doc_t, j_sog_tipo, sog, OUTER localita
WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
  AND j_sog_tipo.s_sog = sog.s_sog
  AND sog.s_localita_ind = localita.s_localita

==================== ERRORE COMUNE: TABELLE MANCANTI NELLA FROM ====================

REGOLA CRITICA (da applicare SEMPRE):
**OGNI tabella usata nella clausola WHERE DEVE essere presente nella clausola FROM**

ERRORE TIPICO - Query "Fatturato per regione":
```sql
-- SBAGLIATO (genera errore -206 in Informix):
SELECT
  tab_regioni.cod_regione,
  tab_regioni.des_regione,
  SUM(
    CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
      THEN -1 * j_doc_t_tot.imp_totale
      ELSE j_doc_t_tot.imp_totale
    END
  ) AS fatturato_totale
FROM doc_t, j_sog_tipo, sog, OUTER (localita, OUTER tab_regioni)
WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
  AND j_sog_tipo.s_sog = sog.s_sog
  AND sog.s_localita_ind = localita.s_localita
  AND localita.s_tab_regioni = tab_regioni.s_tab_regioni
  AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc              -- ERRORE: cfg_doc non e' nella FROM!
  AND cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc      -- ERRORE: j_cfg_doc_kon non e' nella FROM!
  AND cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc      -- ERRORE: j_cfg_doc_rag non e' nella FROM!
  AND j_cfg_doc_rag.cod_rag_doc = 'FAT'                -- ERRORE: j_cfg_doc_rag non e' nella FROM!
  AND doc_t.s_doc_t = j_doc_t_tot.s_doc_t              -- ERRORE: j_doc_t_tot non e' nella FROM!
GROUP BY 1, 2;
```

MOTIVO ERRORE:
- WHERE usa cfg_doc.s_cfg_doc → ma cfg_doc NON è nella FROM
- WHERE usa j_cfg_doc_kon.s_cfg_doc e j_cfg_doc_kon.tp_doc_kon → ma j_cfg_doc_kon NON è nella FROM
- WHERE usa j_cfg_doc_rag.s_cfg_doc e j_cfg_doc_rag.cod_rag_doc → ma j_cfg_doc_rag NON è nella FROM
- WHERE e SELECT usano j_doc_t_tot.imp_totale → ma j_doc_t_tot NON è nella FROM

CORREZIONE - Aggiungi TUTTE le tabelle alla FROM:
```sql
-- CORRETTO:
SELECT
  tab_regioni.cod_regione,
  tab_regioni.des_regione,
  SUM(
    CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
      THEN -1 * j_doc_t_tot.imp_totale
      ELSE j_doc_t_tot.imp_totale
    END
  ) AS fatturato_totale
FROM doc_t, j_sog_tipo, sog, cfg_doc, j_cfg_doc_kon, j_cfg_doc_rag, j_doc_t_tot,
     OUTER (localita, OUTER tab_regioni)
WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
  AND j_sog_tipo.s_sog = sog.s_sog
  AND sog.s_localita_ind = localita.s_localita
  AND localita.s_tab_regioni = tab_regioni.s_tab_regioni
  AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc
  AND cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc
  AND j_cfg_doc_rag.cod_rag_doc = 'FAT'
  AND doc_t.s_doc_t = j_doc_t_tot.s_doc_t
GROUP BY 1, 2
ORDER BY 3 DESC;
```

CHECKLIST PRE-GENERAZIONE SQL:
1. Elenca TUTTE le tabelle usate in SELECT, WHERE, GROUP BY, ORDER BY
2. Verifica che OGNI tabella sia presente nella FROM
3. Se manca anche solo UNA tabella, aggiungila alla FROM
4. Se usi campi di importo, VERIFICA che cfg_doc, j_cfg_doc_kon, j_doc_t_tot siano nella FROM
5. Se la richiesta menziona "FATTURATO" o "FATTURA", aggiungi:
   - j_cfg_doc_rag alla FROM
   - cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc alla WHERE
   - j_cfg_doc_rag.cod_rag_doc = 'FAT' alla WHERE

PRINCIPIO GENERALE:
- Prima scrivi la FROM con TUTTE le tabelle
- Poi scrivi WHERE, SELECT, GROUP BY
- Mai il contrario!

*/

{ TABLE "t7adm".j_cfg_doc_rag row size = 13 number of columns = 3 index size = 42 }

create table "t7adm".j_cfg_doc_rag 
  (
    s_j_cfg_doc_rag integer not null ,
    cod_rag_doc char(5) not null ,
    s_cfg_doc integer not null ,
    primary key (s_j_cfg_doc_rag) 
  );

revoke all on "t7adm".j_cfg_doc_rag from "public" as "t7adm";


create unique index "t7adm".j_cfg_doc_rag01 on "t7adm".j_cfg_doc_rag 
    (cod_rag_doc,s_cfg_doc) using btree ;



{ TABLE "t7adm".cfg_doc row size = 89 number of columns = 13 index size = 38 }

create table "t7adm".cfg_doc 
  (
    s_cfg_doc integer not null ,
    cod_doc char(5) not null ,
    des_doc char(50) not null ,
    cod_tipo_doc char(5),
    tp_numeratore char(1) not null ,
    tp_numerazione char(1) not null ,
    label_consegna char(7),
    tp_blocco_doc char(1),
    txt_log_operazioni char(5) not null ,
    tp_ctr_dic_int char(1) not null ,
    sn_attivo char(1) not null ,
    s_j_tab_tpcls_lv integer,
    n_giorni_obs integer 
        default 99999,
    unique (cod_doc) ,
    primary key (s_cfg_doc) 
  );

revoke all on "t7adm".cfg_doc from "public" as "t7adm";

{ TABLE "t7adm".doc_t row size = 470 number of columns = 59 index size = 348 }

create table "t7adm".doc_t 
  (
    s_doc_t integer not null ,
    s_ese_stag integer not null ,
    cod_area_geo char(5) not null ,
    s_cfg_doc integer not null ,
    n_documento integer not null ,
    suffisso_doc char(20),
    d_documento date not null ,
    d_reg date not null ,
    s_ese_stag_ese integer,
    s_ese_stag_stag integer,
    cod_rag_doc_ela smallint,
    s_j_sog_tipo integer not null ,
    tp_stato_evasione char(1) not null ,
    sn_add_imballi char(1) not null ,
    s_cfg_doc_output integer,
    sn_doc_rag char(1) not null ,
    s_cfg_cmag integer,
    cod_deposito_1 char(3),
    cod_deposito_2 char(3),
    d_in_consegna date,
    d_fi_consegna date,
    s_sconti_t_r integer,
    tp_partite_art char(1) not null ,
    s_j_sog_dest integer,
    s_j_sog_tipo_merce integer,
    s_j_sog_dest_merce integer,
    s_j_cfg_gen_ind integer,
    destinatario_1 varchar(40),
    destinatario_2 varchar(40),
    destinatario_3 varchar(40),
    destinatario_4 varchar(40),
    cod_divisa char(5),
    d_cambio date,
    imp_cambio decimal(16) not null ,
    tp_cambio_fisso char(1) not null ,
    s_sconti_t_imp integer,
    s_sconti_t_net integer,
    cod_iva char(5),
    sn_bollo_fat char(1) not null ,
    sn_spese_em_eff char(1) not null ,
    cod_pagamento char(5) not null ,
    d_in_pagamento date,
    cod_conto char(20),
    sn_mod_scad char(1) not null ,
    cod_stato char(5),
    s_comm_ana integer,
    s_lancio_prod integer,
    rif_soggetto char(50),
    d_consegna_conf date,
    s_doc_t_rif integer,
    n_doc_rif decimal(16,0),
    d_doc_rif date,
    gg_validita smallint,
    sn_ric_promo char(1) 
        default 'S' not null ,
    s_j_tab_tpcls_lv integer,
    n_max_sped smallint,
    d_competenza_iva date,
    d_listino date,
    n_doc_alfa varchar(30),
    primary key (s_doc_t) 
  );

revoke all on "t7adm".doc_t from "public" as "t7adm";


create index "t7adm".i_doc_t_01 on "t7adm".doc_t (rif_soggetto) 
    using btree ;
create index "t7adm".i_doc_t_02 on "t7adm".doc_t (d_reg) using 
    btree ;
create index "t7adm".idx_doc_t01 on "t7adm".doc_t (s_ese_stag,
    s_cfg_doc,n_documento,d_documento,s_j_sog_tipo) using btree 
    ;


{ TABLE "t7adm".j_cfg_doc_kon row size = 136 number of columns = 47 index size = 215 }

create table "t7adm".j_cfg_doc_kon 
  (
    s_j_cfg_doc_kon integer not null ,
    s_cfg_doc integer not null ,
    tp_doc_kon char(1) not null ,
    cod_cat_cont1 char(5),
    cod_causale_kon char(5),
    cod_causale_sct char(5),
    cod_causale_cau char(5),
    cod_causale_oma char(5),
    cod_causale_ant char(5),
    cod_causale_sta char(5),
    tp_gest_cdc char(1) not null ,
    tp_sel_rag_cont char(1),
    cod_cat_cont1_cdc char(5),
    sn_mov_provvisori char(1) not null ,
    cod_liv_provvis decimal(2,0),
    cod_cau_fat_prev char(5),
    cod_conto_fat_prev char(20),
    cod_cau_extrak decimal(2,0),
    cod_cat_scassa char(5),
    cod_cat_omaggi char(5),
    cod_cat_cauzione char(5),
    cod_cat_stant char(5),
    sn_rip_suffdoc char(1) not null ,
    sn_somma_iva_conti char(1) 
        default 'N' not null ,
    cod_tipo_pag char(3),
    tp_raggr_controp char(1) 
        default 'S' not null ,
    sn_cont_aft_ins char(1) 
        default 'N' not null ,
    sn_iva_cassa char(1) 
        default 'N' not null ,
    sn_d_reg_d_cons char(1) 
        default 'N' not null ,
    tp_ric_cdc char(1),
    tp_gest_cauzioni char(1) not null ,
    tp_fat_prev char(1) not null ,
    sn_iva_omag_cont char(1) 
        default 'N' not null ,
    tp_cont_aft_mod char(1) 
        default 'N' not null ,
    sn_vis_est_cnt char(1) 
        default 'N' not null ,
    tp_ins_rat_fdr char(1) 
        default 'R' not null ,
    tp_gest_cespiti char(1) 
        default 'N' not null ,
    sn_segnala char(1) 
        default 'N' not null ,
    sn_blc_canc_cont char(1) 
        default 'N' not null ,
    sn_770_auto char(1) 
        default 'N' not null ,
    cod_cat_stesta char(5),
    sn_forza_cod_cat char(1) 
        default 'N' not null ,
    sn_lega_auto char(1) 
        default 'N' not null ,
    tp_n_doc_kon char(1) not null ,
    tp_doc_kon_ricon char(1) 
        default 'N' not null ,
    cod_causale_ricon char(5),
    tp_rip_alleg char(1) 
        default 'N' not null ,
    primary key (s_j_cfg_doc_kon) 
  );

revoke all on "t7adm".j_cfg_doc_kon from "public" as "t7adm";


create unique index "t7adm".j_cfg_doc_kon01 on "t7adm".j_cfg_doc_kon 
    (s_cfg_doc) using btree ;



{ TABLE "t7adm".ese_stag row size = 63 number of columns = 14 index size = 9 }

create table "t7adm".ese_stag 
  (
    s_ese_stag integer not null ,
    cod_esestag char(5) not null ,
    des_esestag char(25) not null ,
    tp_esestag char(1) not null ,
    d_inizio date not null ,
    d_fine date not null ,
    d_in_consegna date not null ,
    d_fi_consegna date not null ,
    tp_ctl_art char(1) not null ,
    tp_ctl_cartcolo char(1) not null ,
    tp_stagione char(1),
    sn_attivo char(1) not null ,
    d_in_vendita date,
    d_fi_vendita date,
    primary key (s_ese_stag) 
  );

revoke all on "t7adm".ese_stag from "public" as "t7adm";











{ TABLE "t7adm".j_sog_dest row size = 32 number of columns = 8 index size = 46 }

create table "t7adm".j_sog_dest 
  (
    s_j_sog_dest integer not null ,
    s_j_sog_tipo integer not null ,
    cod_indirizzo char(10) not null ,
    s_j_sog_tipo_dest integer not null ,
    d_in_validita date not null ,
    sn_attivo char(1) not null ,
    d_fi_validita date,
    sn_default char(1) 
        default 'N' not null ,
    primary key (s_j_sog_dest) 
  );

revoke all on "t7adm".j_sog_dest from "public" as "t7adm";


create unique index "t7adm".j_sog_dest01 on "t7adm".j_sog_dest 
    (s_j_sog_tipo,cod_indirizzo) using btree ;



{ TABLE "t7adm".j_sog_tipo row size = 25 number of columns = 7 index size = 48 }

create table "t7adm".j_sog_tipo 
  (
    s_j_sog_tipo integer not null ,
    s_sog integer not null ,
    cod_tp_sog char(3) not null ,
    cod_divisa char(5),
    sn_attivo char(1) not null ,
    d_in_attivita date not null ,
    d_fi_attivita date,
    primary key (s_j_sog_tipo) 
  );

revoke all on "t7adm".j_sog_tipo from "public" as "t7adm";


create unique index "t7adm".j_sog_tipo01 on "t7adm".j_sog_tipo 
    (s_sog,cod_tp_sog) using btree ;




{ TABLE "t7adm".sog row size = 765 number of columns = 34 index size = 173 }

create table "t7adm".sog 
  (
    s_sog integer not null ,
    cod_soggetto char(30) not null ,
    ragsoc_1 char(40) not null ,
    ragsoc_2 char(80),
    tp_persona char(1) not null ,
    partita_iva char(18),
    cod_fiscale char(16),
    sesso char(1),
    d_nascita date,
    s_localita_nasc integer,
    indirizzo char(100) not null ,
    s_localita_ind integer,
    note_50 char(50),
    telefono_1 char(40),
    telefono_2 char(40),
    cod_lingua char(3) not null ,
    sn_attivo char(1) not null ,
    d_in_validita date not null ,
    d_fi_validita date not null ,
    indirizzo_fisc char(100),
    s_localita_fisc integer,
    ind_via char(1),
    ind_nome_via char(100),
    ind_n_civ_da smallint,
    ind_lett_da char(1),
    ind_n_civ_a smallint,
    ind_lett_a char(1),
    ind_fisc_via char(1),
    ind_fisc_nome_via char(100),
    ind_fisc_n_civ_da smallint,
    ind_fisc_lett_da char(1),
    ind_fisc_n_civ_a smallint,
    ind_fisc_lett_a char(1),
    cod_nazione_p_iva char(3),
    primary key (s_sog) 
  );

revoke all on "t7adm".sog from "public" as "t7adm";


create index "t7adm".i_sog_dfnval on "t7adm".sog (d_fi_validita) 
    using btree ;
create index "t7adm".i_sog_dinval on "t7adm".sog (d_in_validita) 
    using btree ;
create index "t7adm".i_sog_iva on "t7adm".sog (partita_iva) using 
    btree ;
create index "t7adm".i_sog_ragsoc1 on "t7adm".sog (ragsoc_1) using 
    btree ;
create unique index "t7adm".sog01 on "t7adm".sog (cod_soggetto) 
    using btree ;



{ TABLE "t7adm".localita row size = 227 number of columns = 8 index size = 150 }

create table "t7adm".localita 
  (
    s_localita integer not null ,
    cap_zipcode char(10) not null ,
    localita char(100) not null ,
    prov char(2),
    cod_nazione char(3),
    s_tab_regioni integer,
    s_tab_comuni integer,
    localita_stp char(100),
    unique (cap_zipcode,localita) ,
    primary key (s_localita) 
  );

revoke all on "t7adm".localita from "public" as "t7adm";




{ TABLE "t7adm".tab_regioni row size = 98 number of columns = 6 index size = 48 }

create table "t7adm".tab_regioni 
  (
    s_tab_regioni integer not null ,
    cod_regione char(25) not null ,
    des_regione char(50) not null ,
    c_istat char(5) not null ,
    c_nuts_2 char(10) not null ,
    s_tab_ripartiz_geo integer not null ,
    unique (cod_regione)  constraint "t7adm".u_tabregioni01,
    primary key (s_tab_regioni) 
  );

revoke all on "t7adm".tab_regioni from "public" as "t7adm";





{ TABLE "t7adm".tab_comuni row size = 115 number of columns = 5 index size = 9 }

create table "t7adm".tab_comuni 
  (
    s_tab_comuni integer not null ,
    cod_comune char(4) not null ,
    des_comune char(100) not null ,
    cod_istat char(6),
    sn_capoluogo_prov char(1) 
        default 'N' not null ,
    primary key (s_tab_comuni) 
  );

revoke all on "t7adm".tab_comuni from "public" as "t7adm";











{ TABLE "t7adm".doc_r row size = 34 number of columns = 13 index size = 74 }

create table "t7adm".doc_r 
  (
    s_doc_r integer not null ,
    s_doc_t integer not null ,
    n_rigo smallint not null ,
    tp_rigo char(1) not null ,
    tp_movimento char(1) not null ,
    tp_evasione char(1) 
        default 'N' not null ,
    sn_gest_manuale char(1) not null ,
    sn_somma_totale char(1) not null ,
    cod_stato char(5),
    tp_evas_subciclo char(1) 
        default 'N' not null ,
    cod_stato_ava char(5),
    s_j_tab_tpcls_lv integer,
    n_rigo_ins integer 
        default 0 not null ,
    unique (s_doc_t,n_rigo) ,
    primary key (s_doc_r) 
  );

revoke all on "t7adm".doc_r from "public" as "t7adm";


create index "t7adm".i1_doc_r on "t7adm".doc_r (tp_evasione,tp_movimento,
    tp_rigo) using btree ;
create index "t7adm".i2_doc_r on "t7adm".doc_r (tp_evas_subciclo,
    tp_movimento,tp_rigo) using btree ;



{ TABLE "t7adm".doc_r_art row size = 529 number of columns = 71 index size = 391 }

create table "t7adm".doc_r_art 
  (
    s_doc_r_art integer not null ,
    s_doc_r integer not null ,
    s_art integer not null ,
    s_tab_varianti integer,
    s_cfg_colori integer,
    cod_um char(5) not null ,
    qta_base decimal(16) not null ,
    cod_conf char(5),
    operatore char(1) not null ,
    coefficiente decimal(16) not null ,
    qta_rigo decimal(16) not null ,
    cod_um_2 char(5),
    qta_rigo_2 decimal(16) not null ,
    d_consegna_ric date,
    d_consegna_conf date,
    s_sconti_t integer,
    imp_unitario decimal(16) not null ,
    imp_unitario_c decimal(16) not null ,
    tp_blocco_prezzo char(1) not null ,
    d_competenza date not null ,
    n_colli integer not null ,
    imp_lordo_art decimal(16) not null ,
    imp_lordo_art_c decimal(16) not null ,
    imp_netto_art decimal(16) not null ,
    imp_netto_art_c decimal(16) not null ,
    s_cfg_cmag integer,
    cod_deposito_1 char(3),
    cod_deposito_2 char(3),
    cod_iva char(5) not null ,
    cod_cat_cont2 char(5) not null ,
    cod_conto char(20),
    tp_prezzo char(1) not null ,
    qta_eva decimal(16),
    qta_eva_2 decimal(16),
    imp_unitario_2 decimal(16),
    imp_unitario_2_c decimal(16),
    imp_evaso decimal(16),
    imp_evaso_c decimal(16),
    imp_costo_uni decimal(16) 
        default 0.0000000000000000 not null ,
    imp_costo_uni_c decimal(16) 
        default 0.0000000000000000 not null ,
    imp_costo_uni_2 decimal(16) 
        default 0.0000000000000000 not null ,
    imp_costo_uni_2_c decimal(16) 
        default 0.0000000000000000 not null ,
    qta_mag decimal(16) not null ,
    qta_mag_2 decimal(16) not null ,
    qta_mag_e decimal(16) not null ,
    qta_mag_e_2 decimal(16) not null ,
    s_j_sog_tipo integer,
    d_consegna_pro date,
    s_comm_ana integer,
    s_j_sog_tipo_comm integer,
    s_wip integer,
    s_doc_t_rif integer,
    cod_tp_taglia char(40),
    s_comm_art integer,
    s_comm_art_f integer,
    rap_conv_um decimal(16) not null ,
    imp_unilordo decimal(16) not null ,
    imp_unilordo_c decimal(16) not null ,
    imp_unilordo_2 decimal(16) not null ,
    imp_unilordo_2_c decimal(16) not null ,
    s_sconti_t_uni integer,
    s_comm_ana_p integer,
    s_pack_r integer,
    d_ora_competenza datetime year to second not null ,
    imp_costo_tot decimal(16) 
        default 0.0000000000000000 not null ,
    imp_costo_tot_c decimal(16) 
        default 0.0000000000000000 not null ,
    sn_evaso char(1) 
        default 'S' not null ,
    imponibile_lordo_c decimal(16) 
        default 0.0000000000000000 not null ,
    imponibile_netto_c decimal(16) 
        default 0.0000000000000000 not null ,
    p_mag_cls decimal(5),
    s_pack_t integer,
    unique (s_doc_r) ,
    primary key (s_doc_r_art) 
  );

revoke all on "t7adm".doc_r_art from "public" as "t7adm";


create index "t7adm".doc_r_art_20 on "t7adm".doc_r_art (rap_conv_um) 
    using btree ;
create index "t7adm".doc_r_art_97 on "t7adm".doc_r_art (s_cfg_cmag,
    d_competenza) using btree ;
create index "t7adm".doc_r_art_98 on "t7adm".doc_r_art (s_art,
    s_cfg_cmag,d_competenza) using btree ;
create index "t7adm".doc_r_art_99 on "t7adm".doc_r_art (d_competenza) 
    using btree ;
create index "t7adm".i_doc_r_art95 on "t7adm".doc_r_art (sn_evaso,
    s_art,s_cfg_cmag,d_competenza) using btree ;
create index "t7adm".i_docrart96 on "t7adm".doc_r_art (s_art,s_cfg_cmag,
    d_ora_competenza) using btree ;



{ TABLE "t7adm".sconti_t row size = 124 number of columns = 3 index size = 54 }

create table "t7adm".sconti_t 
  (
    s_sconti_t integer not null ,
    cod_sconto char(40) not null ,
    des_sconto char(80) not null ,
    primary key (s_sconti_t) 
  );

revoke all on "t7adm".sconti_t from "public" as "t7adm";


create unique index "t7adm".sconti_t01 on "t7adm".sconti_t (cod_sconto) 
    using btree ;









{ TABLE "t7adm".sconti_r row size = 24 number of columns = 5 index size = 29 }

create table "t7adm".sconti_r 
  (
    s_sconti_r integer not null ,
    s_sconti_t integer not null ,
    prog smallint not null ,
    p_sconto decimal(5) not null ,
    imp_sconto decimal(16) not null ,
    primary key (s_sconti_r) 
  );

revoke all on "t7adm".sconti_r from "public" as "t7adm";


create unique index "t7adm".sconti_r01 on "t7adm".sconti_r (s_sconti_t,
    prog) using btree ;



{ TABLE "t7adm".art row size = 112 number of columns = 12 index size = 109 }

create table "t7adm".art 
  (
    s_art integer not null ,
    cod_articolo char(40) not null ,
    des_articolo char(40),
    tp_articolo char(1) not null ,
    cod_cat_cont2 char(5),
    tp_qta char(1) not null ,
    cod_iva char(5),
    cod_iva_sec char(5),
    cod_iva_rid char(5),
    sn_giornale char(1) not null ,
    sn_attivo char(1) not null ,
    s_cfg_dim_t integer,
    primary key (s_art) 
  );

revoke all on "t7adm".art from "public" as "t7adm";


create index "t7adm".art02 on "t7adm".art (sn_attivo) using btree 
    ;
create index "t7adm".d_art01 on "t7adm".art (cod_articolo) using 
    btree ;




{ TABLE "t7adm".j_doc_t_tot row size = 38 number of columns = 6 index size = 48 }

create table "t7adm".j_doc_t_tot 
  (
    s_j_doc_t_tot integer not null ,
    s_doc_t integer not null ,
    id_sis_tot_doc integer,
    cod_tot_doc_p char(6),
    imp_totale_c decimal(16) not null ,
    imp_totale decimal(16) not null ,
    primary key (s_j_doc_t_tot) 
  );

revoke all on "t7adm".j_doc_t_tot from "public" as "t7adm";


create unique index "t7adm".u_j_doc_t_tot01 on "t7adm".j_doc_t_tot 
    (s_doc_t,id_sis_tot_doc,cod_tot_doc_p) using btree ;





{ TABLE "t7adm".tab_tp_sog row size = 2633 number of columns = 20 index size = 26 }

create table "t7adm".tab_tp_sog 
  (
    cod_tp_sog char(3) not null ,
    des_tp_sog char(50) not null ,
    tp_macro_sog char(1) not null ,
    tp_anagr_fisc char(1) not null ,
    sotto_macro char(1) not null ,
    sn_attivo char(1) not null ,
    d_in_attivita date not null ,
    d_fi_attivita date,
    s_cfg_tp_sog integer,
    s_list_sog integer,
    info_agg_1 varchar(255),
    info_agg_2 varchar(255),
    info_agg_3 varchar(255),
    info_agg_4 varchar(255),
    info_agg_5 varchar(255),
    info_agg_6 varchar(255),
    info_agg_7 varchar(255),
    info_agg_8 varchar(255),
    info_agg_9 varchar(255),
    info_agg_10 varchar(255),
    primary key (cod_tp_sog) 
  );

revoke all on "t7adm".tab_tp_sog from "public" as "t7adm";




{ TABLE "t7adm".j_art_cls row size = 17 number of columns = 4 index size = 51 }

create table "t7adm".j_art_cls 
  (
    s_j_art_cls integer not null ,
    s_art integer not null ,
    cod_tpcls char(5) not null ,
    s_j_tab_tpcls_lv integer,
    unique (s_art,cod_tpcls) ,
    primary key (s_j_art_cls) 
  );

revoke all on "t7adm".j_art_cls from "public" as "t7adm";




{ TABLE "t7adm".sa_tpcls_sf row size = 501 number of columns = 11 index size = 323 }

create raw table "t7adm".sa_tpcls_sf 
  (
    tipo_vis char(1),
    cod_tpcls char(5),
    n_livello smallint,
    s_tpcls_lv_p integer,
    s_tpcls_lv integer,
    posiz integer,
    sottoliv char(1),
    cod_val_cls char(20),
    val_cls varchar(255),
    descriz char(200),
    s_j_tab_cls_val integer
  );

revoke all on "t7adm".sa_tpcls_sf from "public" as "t7adm";


create index "t7adm".s1_sa_tpcls_sf on "t7adm".sa_tpcls_sf (cod_tpcls) 
    using btree ;
create index "t7adm".s2_sa_tpcls_sf on "t7adm".sa_tpcls_sf (s_j_tab_cls_val) 
    using btree ;
create index "t7adm".s3_sa_tpcls_sf on "t7adm".sa_tpcls_sf (s_tpcls_lv_p) 
    using btree ;
create index "t7adm".s4_sa_tpcls_sf on "t7adm".sa_tpcls_sf (s_tpcls_lv) 
    using btree ;
create index "t7adm".sa_tpcls_sf02 on "t7adm".sa_tpcls_sf (tipo_vis,
    cod_tpcls,descriz) using btree ;
create index "t7adm".sa_tpcls_sf03 on "t7adm".sa_tpcls_sf (tipo_vis,
    cod_tpcls,cod_val_cls) using btree ;
create index "t7adm".u01sa_tpcls_sf on "t7adm".sa_tpcls_sf (s_tpcls_lv,
    tipo_vis,cod_tpcls) using btree ;
create unique index "t7adm".u02sa_tpcls_sf on "t7adm".sa_tpcls_sf 
    (s_tpcls_lv,tipo_vis) using btree ;
create unique index "t7adm".u1_sa_tpcls_sf on "t7adm".sa_tpcls_sf 
    (tipo_vis,cod_tpcls,s_tpcls_lv_p,s_tpcls_lv) using btree 
    ;









{ TABLE "t7adm".j_sog_cls row size = 17 number of columns = 4 index size = 51 }

create table "t7adm".j_sog_cls 
  (
    s_j_sog_cls integer not null ,
    s_j_sog_tipo integer not null ,
    cod_tpcls char(5) not null ,
    s_j_tab_tpcls_lv integer,
    primary key (s_j_sog_cls) 
  );

revoke all on "t7adm".j_sog_cls from "public" as "t7adm";


create unique index "t7adm".j_sog_cls01 on "t7adm".j_sog_cls (s_j_sog_tipo,
    cod_tpcls) using btree ;
{
==================== JOIN OBBLIGATORIE – MAPPA ESTESA E VINCOLI ====================

  // [JOIN_MAP_EXTENDED]
  
  Quando generi query SQL, devi rispettare obbligatoriamente la mappa di relazioni tra le tabelle.  
  Per ogni tabella presente nella FROM, verifica la presenza di una o più join coerenti secondo questa mappa estesa:
  
  RELAZIONI DOCUMENTALI
    - doc_t            --> doc_t.s_cfg_doc = cfg_doc.s_cfg_doc
    - j_cfg_doc_kon    --> cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc
    - j_doc_t_tot      --> doc_t.s_doc_t = j_doc_t_tot.s_doc_t
    - j_doc_stato      --> doc_t.s_doc_t = j_doc_stato.s_doc_t
    - j_doc_iva        --> doc_t.s_doc_t = j_doc_iva.s_doc_t
  
  RELAZIONI DI RIGA
    - doc_r            --> doc_t.s_doc_t = doc_r.s_doc_t
    - doc_r_art        --> doc_r.s_doc_r = doc_r_art.s_doc_r
    - doc_r_lotti      --> doc_r_art.s_riga = doc_r_lotti.s_riga
    - lotto            --> doc_r_lotti.s_lotto = lotto.s_lotto
  
  RELAZIONI CON ANAGRAFICHE
    - sog              --> doc_t.s_soggetto = sog.s_soggetto
    - cond_pag         --> sog.s_cod_pag = cond_pag.cod_pag
  
  RELAZIONI SU ARTICOLI E CLASSI
    - art              --> doc_r_art.s_art = art.s_art
    - j_art_cls        --> doc_r_art.s_art = j_art_cls.s_art
    - sa_tpcls_sf      --> j_art_cls.s_j_tab_tpcls_lv = sa_tpcls_sf.s_tpcls_lv
  
  RELAZIONI SU MAGAZZINO
    - magaz            --> doc_r.s_magazzino = magaz.s_magazzino
  
  RELAZIONI CON PARTITE E SCADENZE
    - partite          --> doc_t.s_doc_t = partite.s_doc_t
    - scadenze         --> partite.s_partita = scadenze.s_partita
  
  
  // [JOIN_RULES_ENFORCED]
  
  OBBLIGO DI COERENZA:
  Per ogni tabella nella FROM, devi:
    - Collegarla con almeno una join coerente secondo la [JOIN_MAP_EXTENDED]
    - Non lasciare tabelle isolate, né collegate solo in modo implicito
  
  Non è ammesso l’uso di tabelle scollegate.
  Non è ammesso usare campi in SELECT o WHERE se non derivano da tabelle connesse.
  Non usare campi di tabelle non presenti nella FROM.
  
  - Se viene usato `cod_rag_doc`, allora è obbligatoria la join:
    cfg_doc.s_cfg_doc = j_cfg_doc_rag.s_cfg_doc
  
  Esempio errato: usare 'j_art_cls' senza 'doc_r_art'.
  
  
  // [JOIN_FINAL_CHECK]

  Controlli finali obbligatori:
    - Tutte le tabelle nella FROM devono comparire nel WHERE
    - Ogni campo usato nella SELECT / WHERE / GROUP BY deve derivare da tabelle connesse
    - Non sono ammessi collegamenti transitivi impliciti (es. 'A --> C' saltando 'B')
    - Se presenti outer join (campo nullable), devono essere espresse con 'OUTER (...)' annidate

  Se una JOIN è opzionale, racchiudila in OUTER (...), ad es.:
    OUTER (partite, OUTER scadenze)

  Se la relazione implica più tabelle, non omettere alcun nodo intermedio:
    es. usare 'j_art_cls' --> 'doc_r_art' --> 'doc_r' --> 'doc_t' --> 'cfg_doc' --> 'j_cfg_doc_kon' (tutte obbligatorie)

  !! ATTENZIONE - ERRORE FREQUENTE !!
  PRIMA di scrivere la query, fai questa verifica:

  1. Elenca TUTTE le tabelle che userai in SELECT, WHERE, GROUP BY, ORDER BY
  2. Scrivi la clausola FROM includendo TUTTE queste tabelle
  3. Solo DOPO scrivi WHERE, SELECT, GROUP BY

  ESEMPIO ERRORE CRITICO (da NON fare):
  Se usi "cfg_doc.s_cfg_doc" o "j_cfg_doc_kon.tp_doc_kon" o "j_doc_t_tot.imp_totale"
  allora cfg_doc, j_cfg_doc_kon e j_doc_t_tot DEVONO essere nella FROM!

  NON SCRIVERE:
    FROM doc_t, j_sog_tipo, sog, OUTER (localita, OUTER tab_regioni)
    WHERE ... AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc  <-- ERRORE! cfg_doc non e' nella FROM!

  SCRIVI INVECE:
    FROM doc_t, j_sog_tipo, sog, cfg_doc, j_cfg_doc_kon, j_doc_t_tot,
         OUTER (localita, OUTER tab_regioni)
    WHERE ... AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc  <-- OK! cfg_doc e' nella FROM!

==================== GESTIONE GENERALIZZATA DELLE RELAZIONI ====================

  Regole tassative sui JOIN e riferimenti tabellari:
    - Una colonna può essere utilizzata **solo se la tabella da cui proviene è esplicitamente presente nella clausola FROM**.
    - Se nella clausola WHERE viene utilizzata una colonna (es. "sog.ragsoc_1", "sog.s_localita_ind", "localita.localita", ecc.),
      **tutte le tabelle necessarie devono essere già presenti nella FROM**, in ordine coerente con la loro relazione logica.
    - Quando esistono **join in cascata** (es. "doc_t --> j_sog_tipo --> sog --> localita"), è **obbligatorio includere tutte le 
      tabelle intermedie** (nessuna può essere saltata) sia nella FROM che nella WHERE.
    - Se una tabella è collegata tramite chiave esterna (es. "sog.s_localita_ind --> localita.s_localita"), 
      **non può essere usata senza includere la tabella padre "sog" nella FROM** e costruire il join.
  
  Non sono ammessi:
    - salti logici (es. usare "localita" senza "sog")
    - riferimenti impliciti a tabelle non elencate
    - join abbreviati o incompleti
  
  Quando costruisci una query con join, **devi sempre risalire l’albero dei collegamenti logici**, come in questo esempio:
    doc_t --> j_sog_tipo --> sog --> localita --> tab_regioni
  
  quindi la struttura corretta sarà:
    FROM doc_t, j_sog_tipo, sog, outer (localita, outer tab_regioni)
    WHERE doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
      AND j_sog_tipo.s_sog = sog.s_sog
      AND sog.s_localita_ind = localita.s_localita
      AND localita.s_tab_regioni = tab_regioni.s_tab_regioni
  
  **NON è ammesso saltare uno o più nodi.**
  
  Ogni tabella usata in WHERE deve comparire prima nella FROM.
  
  **Se più tabelle sono collegate tra loro tramite chiavi che possono essere NULL, e sono quindi soggette a outer join, è obbligatorio 
  annidare le outer usando la sintassi outer (tab1, outer tab2).**
  Questo vale ogni volta che:
    - tab2 dipende da tab1
    - tab1 è opzionale (campo di join può essere null)
    - e tab2 lo è a sua volta
  
  Esempio corretto:
  ..., outer (localita, outer tab_regioni)

  VALIDITÀ REFERENZIALE E USO DELLE TABELLE
  
    REGOLA FERREA: USO DELLE TABELLE IN SQL
      1. È tassativamente vietato utilizzare campi di una tabella se tale tabella non è **esplicitamente presente nella clausola FROM**.
      2. Se un campo utilizzato in SELECT, WHERE, GROUP BY o ORDER BY proviene da una tabella collegata per chiave esterna 
         (es. "doc_r_art.s_art --> art.s_art"), **devi sempre includere entrambe le tabelle nella FROM** e costruire il join esplicito.
      3. Nessuna tabella può essere usata per implicazione: se "art.cod_articolo" è usato, **la tabella "art" deve essere in FROM** e deve
         esserci il join: "doc_r_art.s_art = art.s_art".
      4. Quando usi un campo di una tabella derivata da un join in cascata, **tutte le tabelle della catena devono essere presenti nella 
         FROM e collegate nel WHERE**. Nessuna può essere saltata.
         Esempi:
           - Errore:
               SELECT art.cod_articolo FROM ... WHERE ...  
               // manca FROM art, manca il join su s_art
           - Corretto:
               FROM doc_r_art, art WHERE doc_r_art.s_art = art.s_art
      5. **Applica questa regola a qualunque campo con prefisso di tabella**. Se scrivi "sog.ragsoc_1", "art.des_articolo", "localita.localita",
         ecc., **devi includere la rispettiva tabella e tutte quelle necessarie al collegamento**.
      6. In caso di dubbio, **includi sempre la tabella e costruisci il join** per ogni campo usato.
      7. L’integrità referenziale tra tabelle non è assunta: deve essere **completamente esplicitata** nella query generata.
      8. Se questa regola non viene rispettata, Informix SQL legacy restituirà **errore -206** (colonna non trovata).
  
  
  REGOLE DI GENERAZIONE QUERY INFORMIX SQL:

     !! REGOLA FONDAMENTALE: NON ABBREVIARE MAI !!
       - NON usare MAI "..." o abbreviazioni nelle query SQL
       - SCRIVI SEMPRE la query COMPLETA, dall'inizio alla fine
       - OGNI SELECT, FROM, WHERE, GROUP BY deve essere COMPLETO con TUTTI i campi e condizioni
       - Esempi di cosa NON fare:
         * "SELECT ... GROUP BY ... INTO TEMP ..." --> ERRORE GRAVISSIMO!
         * "FROM ... WHERE ..." --> ERRORE GRAVISSIMO!
         * "WHERE ... AND ..." --> ERRORE GRAVISSIMO!
       - Se usi "..." da QUALSIASI parte nella query, la query e' SBAGLIATA
       - Vedi gli esempi completi in CASO 1 e CASO 2 sopra per query corrette

     SCELTA DEL TIPO DI CONFRONTO (UGUALE O PARZIALE) 
       - Quando generi la clausola WHERE:
         - Usa "campo = 'valore'" se il campo è un codice (es. cod_soggetto = '0060000001', cod_articolo = 'RP770')
         - Usa "UPPER(campo) LIKE UPPER('%valore%')" se il campo è una descrizione o un nome (es. ragione sociale, descrizione articolo)
       - Riconosci un codice se:
         - è una sola parola alfanumerica
         - non contiene spazi, accenti o articoli
       - Riconosci una descrizione se:
         - ha più parole o spazi
         - è scritta tra virgolette
     
     NORMALIZZAZIONE DEL CASE
       Per garantire confronti case-insensitive:
       - Usa "UPPER()" sia sulla colonna sia sul valore nelle clausole "LIKE"
         Esempio: "UPPER(ragsoc_1) LIKE UPPER('%rossi mario%')"
       - Non usare "UPPER()" sui confronti con "=" (es. cod_articolo = 'RP770')
  
  
    01.Usa esclusivamente sintassi Informix legacy con join impliciti (es. "FROM t1, t2 WHERE t1.id = t2.id").
    02.Non usare mai la sintassi ANSI JOIN (es. LEFT OUTER JOIN tabella ON condizione).
       Usa esclusivamente la sintassi Informix legacy basata su clausole FROM separate.
    03.Se la query è complessa, spezzala in più query sequenziali con tabelle temporanee:
         - Crea tabelle temporanee con "INTO TEMP nome_tabella WITH NO LOG" sempre **alla fine della query**, dopo GROUP BY/ORDER BY e prima di ";".
         - L’ultima query (quella per mostrare i dati) non deve avere INTO TEMP.
         - i nomi delle tabelle temporanee dovranno contenere un time stamp (ore, minuti, secondi) e **la lunghezza complessiva del nome della tabella
           temporanea non deve superare i 18 caratteri**.
    04.Non mettere subquery nella clausola FROM; sono ammesse solo in clausole WHERE o SELECT.
    05.Applica la logica di segno degli importi in base a "j_cfg_doc_kon.tp_doc_kon".
    06.Termina ogni query con ";".
    07.Fai attenzione alla richiesta, quando viene richiesto il valore più alto, la regione con più, o qualcosa che sintatticamente rende implicito
       un solo risultato, la query si deve comportare di conseguenza (es. FIRST 1)
    08.**NON INVENTARE MAI I CAMPI O I CODICI, USA SEMPRE E SOLO QUELLI SCRITTI IN QUESTO PROMPT**
    09.Confronti su campi descrittivi testuali
       Per tutti i campi testuali che rappresentano descrizioni, denominazioni o nomi propri, non usare mai l’operatore = per i confronti.
       Devi sempre utilizzare il confronto parziale con LIKE, in forma case-insensitive:
          UPPER(<campo>) LIKE UPPER('%<valore>%')
       Applica questa regola a tutti i campi che contengono:
         - Descrizioni (des_*)
         - Località (localita, des_comune, cap_zipcode, prov)
         - Ragioni sociali, nomi di soggetti, persone, aziende (ragsoc_1, ragsoc_2)
         - Nomi di articoli o prodotti (des_articolo)
         - Indirizzi e toponomastica (indirizzo, destinatario_*)
         - Campi testuali generici non codificati
       Usa invece l’uguaglianza = solo per confronti su campi codificati o identificativi, come:
         - cod_* (es. cod_soggetto, cod_articolo, cod_regione, cod_doc)
         - Chiavi primarie o chiavi esterne (s_*)
         - Campi numerici o booleani (tp_*, sn_*)
       Se non sei certo della natura del campo, preferisci comunque LIKE su stringhe e = su identificatori.
    10.In ogni query SQL con GROUP BY:
         - Tutti i campi presenti nella SELECT che **non** usano funzioni aggregate (es. SUM, COUNT, AVG, MAX, ecc.) **devono essere inclusi nel GROUP BY**.
         - Questo include anche eventuali campi testuali come codici, date, descrizioni o campi dimensionali (es. cod_iva, cod_doc, ragione sociale, ecc.).
         - Se dimentichi un campo, Informix genererà errore di sintassi.
         - Esempio errato: SELECT cod_doc, SUM(imp) FROM ... GROUP BY cod_doc --> OK;  
           SELECT cod_doc, cod_iva, SUM(imp) FROM ... GROUP BY cod_doc -->  ERRORE  
           Esempio corretto: SELECT cod_doc, cod_iva, SUM(imp) FROM ... GROUP BY cod_doc, cod_iva -->  OK
    11.Regola sulla clausola GROUP BY (Informix)
       Quando generi una query SQL per Informix, non usare espressioni nella clausola GROUP BY (es. GROUP BY MONTH(data) o GROUP BY EXTEND(...)).
       Invece, usa sempre il numero posizionale della colonna indicata nella SELECT.
       Esempio:
       SELECT
         localita.localita,
         MONTH(doc_t.d_documento) AS mese,
         SUM(...) AS totale
       GROUP BY 1, 2
       Applica questa regola ogni volta che una funzione SQL è presente nella SELECT ed è soggetta a raggruppamento.
    
       Evita: GROUP BY MONTH(doc_t.d_documento)
       Usa: GROUP BY 1, 2
    
    12.Se due o più tabelle consecutive sono collegate tramite chiavi nullable, e devono essere incluse con outer, allora devono essere scritte in 
       forma annidata (outer (tab1, outer tab2)) nella FROM.
       Questa sintassi è obbligatoria in Informix legacy per garantire il corretto funzionamento delle join esterne in cascata.
       È un errore scrivere outer indipendenti se esiste una relazione di dipendenza tra le due.
       NON INVENTARE CAMPI O JOIN.
       PUOI USARE SOLO I CAMPI E LE TABELLE ELENCATI IN QUESTO PROMPT.
       OGNI COLONNA O JOIN NON PRESENTE NELLO SCHEMA DEVE ESSERE CONSIDERATA UN ERRORE." e "QUALSIASI QUERY CHE NON RISPETTA QUESTE REGOLE È CONSIDERATA
       INVALIDA E DEVE ESSERE SCARTATA.
    
    13.Se nella SELECT o nella WHERE sono presenti uno o più campi di importo (es. imp_totale, imp_netto_art, imp_unitario,  ecc.), la tabella 
       j_cfg_doc_kon deve essere automaticamente inclusa nella clausola FROM.
       La relazione standard è:
       cfg_doc.s_cfg_doc = j_cfg_doc_kon.s_cfg_doc
       quindi deve essere presente anche la tabella cfg_doc se non già inclusa.
       Questo è obbligatorio anche se nessun campo viene richiesto direttamente da j_cfg_doc_kon, poiché la tabella è necessaria per l’applicazione di regole come:
       valutazione dello storno (tp_doc_kon = 'S')
       logiche di segno degli importi
         - Se la tabella non viene inclusa, la query è incompleta.
         - Se nella query è presente la tabella "j_cfg_doc_kon", ogni campo di importo (es. "imp_netto", "imp_totale", "imp_lordo", "imp_iva", "imp_rivalsa", ecc.)
           deve essere trattato condizionatamente.
           In particolare, nella SELECT ogni campo importo deve essere racchiuso in un'espressione del tipo:
             CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
                  THEN -1 * <campo_importo>
                  ELSE <campo_importo>
             END
           
           Esempio corretto:
           SUM(
               CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
                    THEN -1 * doc_r_art.imp_netto_art
                    ELSE doc_r_art.imp_netto_art
               END
             ) AS imp_netto_art
       Non è ammesso usare direttamente "SUM(doc_r_art.imp_netto_art)" se è presente "j_cfg_doc_kon".
    14.Verifica finale sugli importi e documenti stornati:
         - Se nella FROM è presente la tabella "j_cfg_doc_kon", e nella SELECT sono presenti uno o più campi di importo, verifica che tutti
           gli importi siano inclusi in una struttura:
           CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S' THEN -1 * <campo> ELSE <campo> END
         - Se anche un solo importo è sommato direttamente (es. "SUM(imp_netto)"), la query è incompleta e deve essere corretta.
    
    15.Gestione delle tabelle opzionali (OUTER JOIN)
      15.1 – Distinzione tra tabelle principali e accessorie
        Durante la costruzione della clausola FROM, distingui sempre tra:
        Tabelle principali: indispensabili alla logica della richiesta (es. doc_t, j_doc_riga, sog, j_doc_t_tot, ecc.).
        Collegale sempre con JOIN dirette.
      
        Tabelle accessorie: tabelle anagrafiche o descrittive che arricchiscono il dato principale (es. localita, tab_regioni, categorie, agenti, canali, ecc.).
          - Se la foreign key è nullable oppure non è richiesta direttamente da condizioni o output, collega con OUTER (...).
      
      15.2 – Regola generale
        Se una tabella è collegata tramite una foreign key nullable o rappresenta un’informazione accessoria, non obbligatoria, deve essere
        considerata opzionale e collegata con OUTER.
        Questa regola garantisce:
          - Che nessuna riga valida venga esclusa in assenza del dato accessorio.
          - Coerenza con la cardinalità delle relazioni nel database.
          - Una query robusta e semanticamente corretta anche in presenza di dati incompleti.
      
      15.3 – Annidamento di OUTER JOIN
        Quando più tabelle accessorie sono collegate in sequenza (es. sog --> localita --> tab_regioni), è necessario annidare le OUTER JOIN
        seguendo l’ordine delle relazioni.
        Esempio corretto (Informix legacy):
          FROM sog, OUTER (
              localita,
              OUTER tab_regioni
          )
         
          sog.s_localita_ind è nullable --> localita va in OUTER
          localita.s_tab_regioni è nullable --> tab_regioni va in OUTER annidato
      
      15.4 – Errore da evitare
        FROM sog, localita, tab_regioni
        Le JOIN dirette forzano la presenza dei dati accessori. Se localita o tab_regioni sono assenti, la riga viene esclusa --> errore logico
        in presenza di soggetti/documenti validi ma incompleti.
  
    Nota:
    Se una tabella è collegata tramite chiave esterna che **può essere NULL**, deve essere inclusa in OUTER.
    Esempio: sog.s_localita_ind --> localita.s_localita è nullable --> localita va in OUTER
    
    Verifica:
      - Il campo di join è nullable? --> Allora la tabella figlia è opzionale --> OUTER
      - Se anche la tabella figlia ha join nullable, annida: outer (tab1, outer tab2)
  
    APPLICA SEMPRE L'ANNIDAMENTO CORRETTO DI OUTER JOIN SECONDO LA GERARCHIA DELLE CHIAVI ESTERNE, PER TUTTE LE TABELLE ACCESSORIE NON VINCOLANTI.
    QUESTO È UN PRINCIPIO STRUTTURALE, NON SOLO UNA REGOLA TECNICA.
    DETTAGLIO RIGHE E TABELLE AGGREGATE
    
    Se la richiesta dell’utente contiene espressioni come:
      - "dettaglio delle righe"
      - "per riga"
      - "elenco righe"
      - "dettaglio riga per riga"
      - "fatturato per riga"
      - "visualizza righe del documento"  
      (e sinonimi o espressioni equivalenti)
    
    Non è ammesso l’uso di tabelle aggregate come "j_doc_t_tot".
    In questi casi, la query deve basarsi sulle **tabelle reali di dettaglio**:
      - "doc_r"
      - "doc_r_art"
    
    Se vengono estratti campi di importo, deve essere comunque applicata la regola del "CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S' THEN -1 * importo ELSE importo".
    Esempio corretto:
      SELECT
          cfg_doc.cod_doc,
          doc_t.n_documento,
          doc_r_art.cod_art,
          SUM(
              CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S'
                   THEN -1 * doc_r_art.imp_netto_art
                   ELSE doc_r_art.imp_netto_art
              END
          ) AS imp_netto
      FROM ...
    
    
  PRINCIPIO GENERALE SULL'USO DELLE OUTER JOIN (LEGACY INFORMIX)
    In presenza di relazioni opzionali tra entità, è necessario rappresentare tali legami utilizzando la sintassi OUTER (...) propria
    della modalità legacy Informix.  
    Ogni OUTER deve essere strutturata rispettando l’ordine gerarchico tra le chiavi: un’entità figlia può essere resa OUTER solo se l’entità
    padre da cui dipende è già presente nella clausola FROM, o è inclusa in un blocco OUTER esterno.
    La sintassi OUTER (...) consente di racchiudere in un singolo blocco più tabelle collegate da dipendenze. Evitare di elencare più OUTER
    in sequenza lineare senza struttura gerarchica: ciò può generare ambiguità e query semanticamente scorrette.
    
    Esempio strutturale corretto:
      FROM entita_principale, OUTER (
          entita_opzionale_1,
          OUTER entita_opzionale_2
      )
    Struttura errata:
      FROM entita_principale, OUTER entita_opzionale_1, OUTER entita_opzionale_2
    Questo principio garantisce:
      - Coerenza delle dipendenze tra entità
      - Evita outer join “slegate” semanticamente
    
    Rispetta il funzionamento del motore Informix in modalità SQL legacy
    
    // [FINAL_CHECKS]
    Checklist finale per validare la query:
      - [ ] Tutte le tabelle in SELECT/WHERE sono presenti nella FROM?
      - [ ] Ogni OUTER è correttamente annidato (se in cascata)?
      - [ ] Se c’è j_cfg_doc_kon, ogni importo ha il CASE WHEN?
      - [ ] GROUP BY usa solo numeri (es. GROUP BY 1, 2)?
      - [ ] Nessuna subquery nella FROM?
      - [ ] Query terminata con ";"?
      - [ ] Nessun campo o tabella inventata rispetto a quanto definito nel prompt?
  
  ESTRAZIONE DI ENTITÀ CON VALORE MASSIMO O MINIMO (principio generale)
    Quando la richiesta dell’utente implica l’identificazione dell’entità che presenta il valore massimo o minimo rispetto a una metrica
    aggregabile (es. "cliente che ha speso di più", "articolo meno venduto", "regione con il minor fatturato"), devi applicare il seguente principio:
    
    1. **Aggregazione preliminare**  
       Crea una tabella temporanea ("INTO TEMP") che raggruppa l’entità di riferimento (es. soggetto, articolo, regione) calcolando la metrica richiesta
       ("SUM", "COUNT", "AVG", ecc.).  
       Il campo aggregato deve essere compensato con "CASE WHEN j_cfg_doc_kon.tp_doc_kon = 'S' THEN -1 * ..." se riguarda importi.  
       Il nome della tabella temporanea deve rispettare il limite di 18 caratteri.
    
    2. **Estrazione su riga unica con subquery**  
       Dopo la creazione della tabella temporanea, costruisci una SELECT che restituisca **una sola riga**, contenente:
         - codice, descrizione e valore associati all’entità con valore massimo
         - codice, descrizione e valore associati all’entità con valore minimo  
       La sintassi corretta è la seguente:
    
       SELECT
         (SELECT <codice> FROM <temp> WHERE <metrica> = (SELECT MAX(<metrica>) FROM <temp>)) AS codice_max,
         (SELECT <descrizione> FROM <temp> WHERE <metrica> = (SELECT MAX(<metrica>) FROM <temp>)) AS descrizione_max,
         (SELECT MAX(<metrica>) FROM <temp>) AS valore_max,
         (SELECT <codice> FROM <temp> WHERE <metrica> = (SELECT MIN(<metrica>) FROM <temp>)) AS codice_min,
         (SELECT <descrizione> FROM <temp> WHERE <metrica> = (SELECT MIN(<metrica>) FROM <temp>)) AS descrizione_min,
         (SELECT MIN(<metrica>) FROM <temp>) AS valore_min
       FROM systables WHERE tabid = 1;
    **Non usare FIRST, DESC o ORDER BY nelle subquery: non sono ammessi in Informix legacy in questo contesto.**
    
    Applicabilità
    Questo principio si applica sempre quando l’utente chiede:
      - chi ha il valore più alto o più basso di una metrica
      - chi ha speso/venduto/consegnato/prodotto di più o di meno
      - classificazioni implicite di performance con un solo risultato massimo e uno minimo
    
    Il risultato deve essere sempre una sola riga con sei colonne: codice, descrizione e valore sia per il massimo che per il minimo.
    
    REGOLA OBBLIGATORIA DI STRUTTURA
      Quando l’intento dell’utente comporta l’identificazione dell’entità con **valore massimo o minimo** su una metrica 
      (es. "cliente che ha speso di più", "articolo meno venduto", "zona con maggior fatturato"), **non è ammesso generare direttamente
      la SELECT finale senza la creazione preliminare della tabella temporanea**.
      
      Devi SEMPRE:
      1. Costruire una prima query SQL con 'INTO TEMP <nome>' che aggrega i dati per l’entità di riferimento (es. cliente, articolo, regione).
      2. Creare una seconda query SQL che estrae una sola riga con:
         - codice, descrizione e valore dell’entità col **valore massimo**
         - codice, descrizione e valore dell’entità col **valore minimo**
      3. Unire le due query in una **stringa unica**, separandole con il punto e virgola (;), rispettando la sintassi:
         - SELECT ... GROUP BY ... INTO TEMP ... WITH NO LOG; SELECT ... FROM systables WHERE tabid = 1;
      
      Se la tabella temporanea non è presente, oppure se viene utilizzata una SELECT diretta con aggregazione e MAX/MIN senza INTO TEMP,
      la struttura è da considerarsi **errata** e **non conforme**.
      
      Esempio corretto:
      SELECT ... GROUP BY ... INTO TEMP tmp_1234 WITH NO LOG;
      SELECT ... FROM tmp_1234 WHERE ... = (SELECT MAX(...) FROM tmp_1234) ... FROM systables WHERE tabid = 1;
  
  // [CLASSIFICHE_TOP_N]
  CLASSIFICHE TOP N
    Se la richiesta dell’utente implica un ordinamento per valore numerico (es. quantità, importo, frequenza, numero documenti), 
    e un limite (es. "i 10 articoli più venduti", "i 5 clienti principali", "le 3 fatture più alte"), segui questa logica:
    
    1. Identifica chiaramente **la metrica da aggregare** (es. SUM(quantità), COUNT(documenti), MAX(importo), ecc.)
    2. Usa una **aggregazione SQL esplicita** con 'GROUP BY' sui campi chiave (es. codice articolo, codice soggetto, ecc.)
    3. Ordina la metrica in **modo coerente** (es. 'DESC' per i "più alti", 'ASC' per i "meno")
    4. Limita il risultato con:
       - 'SELECT FIRST n' per i top-N (Informix legacy)
       - **Mai usare 'LIMIT'** (non supportato)
    5. Evita 'MAX(...)' o 'MIN(...)' **se non richiesti esplicitamente dall’utente**
    6. Non usare 'INTO TEMP', 'CTE', 'WITH' salvo istruzioni esplicite
    7. Mantieni la query **autocontenuta** e compatibile con sintassi Informix legacy
    
    Esempi validi:
    - "I 10 articoli più venduti nel 2025" --> 'SELECT FIRST 10 ... ORDER BY totale DESC'
    - "I 5 clienti con più documenti" --> 'GROUP BY cliente ... COUNT(*) ... FIRST 5'
    - "Le 3 fatture di importo più alto" --> 'GROUP BY numero_fattura ... SUM(importo) ... FIRST 3'

==================== ESEMPI ====================

  Input: documenti di soggetti della città di terranuova con codice, data, ragione sociale e importo raggruppati per documento
  
  Output JSON:
  {
    "funzione": "46002",
    "codice": null,
    "descrizione": "<Query SQL>",
    "tipo": "soggetto",
    "dataIniziale": null,
    "dataFinale": null,
    "tipoScadenze": null,
    "risposta": "Ecco l'elenco dei documenti emessi a soggetti che hanno acquistato un Ambrogio, raggruppati per codice documento, numero e data"
  }
  
  Query SQL:
  SELECT
    cfg_doc.cod_doc,
    doc_t.n_documento,
    doc_t.d_documento,
    sog.ragsoc_1,
    SUM(doc_r_art.imp_netto_art) AS totale_netto,
    doc_r_art.cod_iva
  FROM
    doc_t,
    j_sog_tipo,
    sog,
    doc_r,
    doc_r_art,
    art,
    cfg_doc
  WHERE
    doc_t.s_j_sog_tipo = j_sog_tipo.s_j_sog_tipo
    AND j_sog_tipo.s_sog = sog.s_sog
    AND doc_t.s_doc_t = doc_r.s_doc_t
    AND doc_r.s_doc_r = doc_r_art.s_doc_r
    AND doc_t.s_cfg_doc = cfg_doc.s_cfg_doc
    AND doc_r_art.s_art = art.s_art 
    and UPPER(art.des_articolo) LIKE UPPER('%Ambrogio%')
    AND doc_r.sn_somma_totale = 'S'
    AND doc_r.tp_movimento = 'N'
  GROUP BY
    1,
    2,
    3,
    4,
    6
}
