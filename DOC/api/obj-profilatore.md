# OBJ_Profilatore — Documentazione Tecnica

**Versione**: 0.6.0
**Data**: 2026-03-12
**File sorgente**: `SRC/OBJ/OBJ_PROFILATORE.sql`

---

## Panoramica

`OBJ_Profilatore` è la superclasse astratta (`NOT INSTANTIABLE NOT FINAL`) da cui ereditano
tutti i tipi dell'applicazione SISTER. Non può essere istanziata direttamente: viene
usata esclusivamente tramite le sue sottoclassi concrete.

Fornisce tre categorie di funzionalità a tutte le sottoclassi:

1. **Campo condiviso `Esito`** — trasporta il risultato di ogni operazione tramite `OBJ_Esito`.
2. **Funzioni statiche di sessione** — lettura degli ID correnti da `CTX_APP_IDS`
   senza necessità di istanziare alcun oggetto.
3. **Costruzione dinamica WHERE** — metodo `BuildWhere` che combina i filtri di
   autorizzazione (`CTX_APP_ABL`) con i filtri di ricerca (`CTX_APP_FLT`), delegando
   la traduzione da nomi logici a colonne fisiche al metodo astratto `RisolviSinonimo`.

---

## Posizione nella Gerarchia

```
OBJ_Profilatore   (questa classe — NOT INSTANTIABLE NOT FINAL)
  ├── OBJ_Sessione
  ├── OBJ_Utente
  ├── OBJ_Profilo
  ├── OBJ_Ruolo
  ├── OBJ_Azione
  ├── OBJ_Privilegio
  └── OBJ_Abilitazione
```

---

## Dipendenze

| Dipendenza | Tipo | Descrizione |
|------------|------|-------------|
| `OBJ_Esito` | Oracle TYPE | Tipo del campo `Esito`; usato per costruire le risposte |
| `CTX_APP_IDS` | Application Context | Contiene `ID_SESSIONE`, `ID_UTENTE`, `ID_PROFILO`, `ID_RUOLO` |
| `CTX_APP_ABL` | Application Context | Filtri di autorizzazione del profilo corrente |
| `CTX_APP_FLT` | Application Context | Filtri di ricerca aggiuntivi impostati a runtime |
| `SESSION_CONTEXT` | Vista Oracle | Usata da `BuildWhere` per iterare sugli attributi dei contesti |

---

## Attributi

| Nome | Tipo | Descrizione |
|------|------|-------------|
| `Esito` | `OBJ_Esito` | Esito dell'ultima operazione eseguita sull'oggetto. Sempre popolato dopo ogni metodo CRUD o chiamata a `BuildWhere`. |

---

## Metodi

### `Info()` — identificativo del tipo

```plsql
MEMBER FUNCTION Info RETURN VARCHAR2
```

Restituisce il nome identificativo del tipo. L'implementazione base restituisce
`'PROFILATORE'`; le sottoclassi fanno override per restituire il proprio nome
(es. `'UTENTE'`, `'SESSIONE'`).

**Utilizzo tipico**: logging e diagnostica.

**Esempio**:
```plsql
DECLARE
  vUtente OBJ_Utente := OBJ_Utente();
BEGIN
  DBMS_OUTPUT.PUT_LINE(vUtente.Info());  -- → 'UTENTE'
END;
```

---

### `MioIdUtente()` — ID utente di sessione

```plsql
STATIC FUNCTION MioIdUtente RETURN NUMBER
```

Legge `ID_UTENTE` dal contesto `CTX_APP_IDS`. Restituisce `NULL` se la sessione
non è attiva. Chiamabile senza istanziare alcun oggetto.

**Esempio**:
```plsql
DECLARE
  vId NUMBER := OBJ_Profilatore.MioIdUtente();
BEGIN
  IF vId IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'Sessione non attiva');
  END IF;
END;
```

---

### `MioIdRuolo()` — ID ruolo di sessione

```plsql
STATIC FUNCTION MioIdRuolo RETURN NUMBER
```

Legge `ID_RUOLO` dal contesto `CTX_APP_IDS`. Usato come guard leggero nei metodi
`Carica()` invocati durante `PKG_APP.Inizializza()`, dove `VerificaAccesso` non
è ancora disponibile.

**Esempio**:
```plsql
-- Pattern usato in Carica() prima che il contesto sia completamente popolato
IF OBJ_Profilatore.MioIdRuolo() IS NULL THEN
  SELF.Esito := OBJ_Esito.Imposta(401, 'Sessione non attiva', NULL, NULL);
  RETURN;
END IF;
```

---

### `MioIdProfilo()` — ID profilo di sessione

```plsql
STATIC FUNCTION MioIdProfilo RETURN NUMBER
```

Legge `ID_PROFILO` dal contesto `CTX_APP_IDS`. Restituisce `NULL` se la sessione
non è attiva.

---

### `MioIdSessione()` — ID sessione corrente

```plsql
STATIC FUNCTION MioIdSessione RETURN VARCHAR2
```

Legge `ID_SESSIONE` (GUID come `VARCHAR2`) dal contesto `CTX_APP_IDS`. Il GUID è
generato con `SYS_GUID()` al momento del login e inserito in `TBL_SESSIONI`.
Restituisce `NULL` se la sessione non è attiva.

---

### `RisolviSinonimo()` — traduzione nome logico → colonna fisica

```plsql
NOT INSTANTIABLE MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2
```

**Metodo astratto** — ogni sottoclasse concreta deve fornire la propria implementazione.

Traduce un nome logico di attributo (come usato nei contesti `CTX_APP_ABL` e `CTX_APP_FLT`)
nella coppia `COLONNA|TIPO` che `BuildWhere` usa per costruire il predicato SQL.

**Formato di ritorno**: `'NOME_COLONNA_FISICA|TIPO'`

| Tipo | Significato | Trattamento in SQL |
|------|-------------|-------------------|
| `V` | VARCHAR2 | avvolto in apici, escape degli apici interni |
| `N` | NUMBER | validato con `TO_NUMBER`, senza apici |
| `D` | DATE | validato con `TO_DATE('YYYY-MM-DD')`, generato `TO_DATE(...)` |

Se il sinonimo non è rilevante per la sottoclasse, restituire `NULL`.
`BuildWhere` ignorerà l'attributo in modo non bloccante (traccerà solo un avviso in `DebugInfo`).

**Esempio implementazione** in `OBJ_Utente`:
```plsql
NOT OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
  RETURN CASE pSinonimo
    WHEN 'ATTIVO'   THEN 'ATTIVO|V'
    WHEN 'COGNOME'  THEN 'COGNOME|V'
    WHEN 'NOME'     THEN 'NOME|V'
    WHEN 'ID_RUOLO' THEN 'ID_RUOLO|N'
    ELSE NULL
  END;
END RisolviSinonimo;
```

---

### `BuildWhere()` — costruzione clausola WHERE profilata

```plsql
MEMBER PROCEDURE BuildWhere(
  pAlias IN  VARCHAR2 DEFAULT NULL,
  pWhere OUT VARCHAR2
)
```

Costruisce dinamicamente la clausola `WHERE` per le query SQL combinando i filtri
di autorizzazione (`CTX_APP_ABL`) e i filtri di ricerca (`CTX_APP_FLT`).

#### Parametri

| Parametro | Modalità | Tipo | Descrizione |
|-----------|----------|------|-------------|
| `pAlias` | `IN` | `VARCHAR2` | Alias della tabella per qualificare le colonne (es. `'U'` → `U.COGNOME`). `NULL` = nessuna qualifica. |
| `pWhere` | `OUT` | `VARCHAR2` | Clausola WHERE senza la parola chiave `WHERE`, pronta per concatenazione. Stringa vuota se nessun filtro è applicabile. `NULL` in caso di errore interno (status 500). |

#### Algoritmo

```
Per ogni attributo distinto presente in CTX_APP_ABL o CTX_APP_FLT:
  1. SELF.RisolviSinonimo(attributo)
     → NULL    : ignora l'attributo (traccia in DebugInfo)
     → 'COL|T' : procedi

  2. Parsing del valore: 'VALORI|OPERATORE'
     (usa l'ultimo '|' come separatore)

  3. Merging ABL + FLT:
     ┌── entrambi presenti con op. '=' ?
     │     → UnisciValori(ABL, FLT) → clausola IN
     │     → se FLT introduce valori nuovi: segnala avviso
     ├── entrambi presenti con operatori diversi ?
     │     → predicato_ABL AND predicato_FLT
     ├── solo ABL presente ?
     │     → predicato_ABL
     └── solo FLT presente ?
           → predicato_FLT

  4. Concatena con ' AND '
```

#### Esito dopo la chiamata

| `SELF.Esito.StatusCode` | Significato |
|------------------------|-------------|
| `200` | Clausola costruita correttamente, nessun avviso |
| `200` + `DebugInfo` | OK con avvisi: sinonimi ignorati e/o FLT allarga la visibilità ABL |
| `500` | Errore interno (es. valore non numerico per tipo `N`, data malformata per tipo `D`) |

#### Formato contesto ABL/FLT

Ogni attributo nei contesti è memorizzato come stringa: `VALORI|OPERATORE`

- `VALORI`: lista di valori separati da `;`
- `OPERATORE`: uno tra `=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `BETWEEN`, `NULL`, `NOTNULL`

**Esempi di valori nei contesti**:

| Valore nel contesto | Predicato generato (campo `ATTIVO`, tipo `V`) |
|---------------------|----------------------------------------------|
| `S|=` | `ATTIVO = 'S'` |
| `S;N|=` | `ATTIVO IN ('S','N')` |
| `B%|LIKE` | `ATTIVO LIKE 'B%'` |
| `\|NULL` | `ATTIVO IS NULL` |
| `2024-01-01;2024-12-31|BETWEEN` | `ATTIVO BETWEEN TO_DATE(...) AND TO_DATE(...)` |

#### Esempio completo di utilizzo

```plsql
DECLARE
  vUtente OBJ_Utente := OBJ_Utente();
  vWhere  VARCHAR2(4000);
  vSql    VARCHAR2(8000);
  vCur    SYS_REFCURSOR;
BEGIN
  -- 1. Costruisce la clausola WHERE combinando ABL e FLT
  vUtente.BuildWhere('U', vWhere);

  -- 2. Verifica l'esito
  IF vUtente.Esito.StatusCode = 500 THEN
    RAISE_APPLICATION_ERROR(-20001, vUtente.Esito.Errori);
  END IF;

  -- 3. Assembla la query
  vSql := 'SELECT U.ID_UTENTE, U.COGNOME, U.NOME FROM UTENTI U';
  IF vWhere IS NOT NULL THEN
    vSql := vSql || ' WHERE ' || vWhere;
  END IF;

  -- 4. Esecuzione
  OPEN vCur FOR vSql;
  -- ...
END;
```

**Con i contesti popolati in questo modo**:
```
CTX_APP_ABL.ATTIVO = 'S|='
CTX_APP_FLT.COGNOME = 'B%|LIKE'
```

**La query generata sarà**:
```sql
SELECT U.ID_UTENTE, U.COGNOME, U.NOME
  FROM UTENTI U
 WHERE U.ATTIVO = 'S'
   AND U.COGNOME LIKE 'B%'
```

---

## Funzioni Interne (private di BuildWhere)

Queste funzioni sono dichiarate come nested functions all'interno di `BuildWhere`
e non sono accessibili dall'esterno.

### `FormatVal(pVal, pTipo)` — formattazione sicura di un valore

Converte un valore testuale nel formato SQL corretto per il tipo dichiarato.
Previene SQL injection validando i tipi `N` e `D` prima di includerli nella query.

| Tipo | Esempio input | Esempio output SQL |
|------|---------------|--------------------|
| `N` | `'42'` | `42` |
| `D` | `'2024-03-15'` | `TO_DATE('2024-03-15','YYYY-MM-DD')` |
| `V` | `D'Amico` | `'D''Amico'` |

### `Predicato(pCampo, pTipo, pValori, pOp)` — costruisce un predicato SQL

Genera il frammento SQL per un singolo campo. Gestisce tutti gli operatori
supportati e delega la formattazione dei valori a `FormatVal`.

### `UnisciValori(pA, pB)` — unione liste senza duplicati

Concatena due liste `;`-separate eliminando i duplicati (case-sensitive).
Usata nel merging ABL+FLT con operatore `=`.

### `HaNuoviValori(pA, pB)` — rilevamento allargamento visibilità

Restituisce `TRUE` se la lista `pB` (FLT) contiene almeno un valore non
presente in `pA` (ABL). Trigger per l'avviso di allargamento della visibilità.

---

## Guida all'Implementazione di una Sottoclasse

Per creare un nuovo tipo che eredita da `OBJ_Profilatore`:

### 1. Dichiarazione del TYPE

```plsql
CREATE OR REPLACE TYPE OBJ_MioTipo UNDER OBJ_Profilatore (
  -- campi specifici del tipo
  IdMioTipo   NUMBER,
  Descrizione VARCHAR2(200),

  -- costruttore
  CONSTRUCTOR FUNCTION OBJ_MioTipo RETURN SELF AS RESULT,

  -- override obbligatorio del metodo astratto
  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,

  -- override facoltativo di Info
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,

  -- metodi specifici
  MEMBER PROCEDURE Crea,
  MEMBER PROCEDURE Modifica,
  MEMBER PROCEDURE Elimina,
  STATIC FUNCTION  Carica(pId IN NUMBER) RETURN OBJ_MioTipo
);
```

### 2. Implementazione di RisolviSinonimo

```plsql
OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
  -- Mappa ogni attributo dei contesti ABL/FLT alla colonna fisica
  RETURN CASE pSinonimo
    WHEN 'DESCRIZIONE' THEN 'DESCRIZIONE|V'
    WHEN 'ID_TIPO'     THEN 'ID_TIPO|N'
    -- Attributi non pertinenti a questo tipo → NULL (ignorati da BuildWhere)
    ELSE NULL
  END;
END RisolviSinonimo;
```

### 3. Utilizzo di BuildWhere in una query

```plsql
STATIC FUNCTION Cerca RETURN SYS_REFCURSOR IS
  vObj OBJ_MioTipo := OBJ_MioTipo();
  vWhere VARCHAR2(4000);
  vCur   SYS_REFCURSOR;
BEGIN
  vObj.BuildWhere('M', vWhere);
  IF vObj.Esito.StatusCode = 500 THEN RETURN NULL; END IF;

  OPEN vCur FOR
    'SELECT M.ID_TIPO, M.DESCRIZIONE FROM MIA_TABELLA M'
    || CASE WHEN vWhere IS NOT NULL THEN ' WHERE ' || vWhere ELSE '' END;
  RETURN vCur;
END Cerca;
```

---

## Note di Sicurezza

- `BuildWhere` **non usa** `DBMS_ASSERT.SIMPLE_SQL_NAME` direttamente, ma
  delega la protezione a `FormatVal` che valida tipi numerici e date prima
  di includerli nella query dinamica.
- I valori `VARCHAR2` sono protetti dall'escape degli apici singoli (`''`).
- I nomi delle colonne fisiche provengono esclusivamente da `RisolviSinonimo`
  (codice hardcoded nelle sottoclassi), non da input utente.

---

## Test e Benchmark

Gli script di test funzionali e di performance per `BuildWhere` si trovano in
`SRC/TEST_APP.sql`. Le procedure rilevanti sono:

| Procedura | Descrizione |
|-----------|-------------|
| `TBW1`..`TBW8` | Test funzionali: coprono tutti gli operatori, il merging ABL+FLT, la deduplicazione, gli avvisi e la gestione degli errori (sinonimo sconosciuto → 400). |
| `TBWP1(pIterazioni)` | Benchmark di performance: 3 scenari (1 FLT baseline, 5 FLT eterogenei, 5 ABL+5 FLT con overlap e merging). Misura in centesimi di secondo. Default: 100 iterazioni per scenario. |

Vedere la tabella completa in [README — Script di Test](../README.md#script-di-test-srctestappsql).

---

## Riferimenti

- [Panoramica API](overview.md)
- [OBJ_Esito — tipo di risposta](../guide/getting-started.md)
- [Getting Started](../guide/getting-started.md)
- [← Torna all'indice](../README.md)
