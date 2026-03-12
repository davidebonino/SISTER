# OBJ_Utente — Documentazione Tecnica

**Tipo Oracle**: `OBJ_Utente UNDER OBJ_Profilatore`
**Tabella fisica**: `UTENTI`
**Sequenza ID**: `UTENTI_ID_UTENTE.NEXTVAL`
**File sorgente**: `SRC/OBJ/OBJ_UTENTE.sql`

---

## Panoramica

`OBJ_Utente` rappresenta un utente del sistema SISTER. Estende `OBJ_Profilatore` e
implementa il pattern CRUD standard con verifica accesso RBAC su ogni operazione di
scrittura tramite `PKG_APP.VerificaAccesso`.

Caratteristiche principali:

- **Soft delete**: `Elimina(pFisica => FALSE)` imposta `Attivo = 'N'`, il record
  rimane fisicamente in tabella.
- **Eliminazione fisica**: `Elimina(pFisica => TRUE)` cancella il record da `UTENTI`.
- **Ricerca profilata**: `Cerca` costruisce la WHERE clause dinamicamente combinando
  i filtri di autorizzazione (`CTX_APP_ABL`) e i filtri di ricerca a runtime
  (`CTX_APP_FLT`) tramite `BuildWhere`.
- **Dati sensibili (GDPR)**: `CodiceFiscale`, `Telefono`, `Cellulare`, `Email` sono
  dati personali. Le password sono hash MD5 e non sono mai esposte dalla `Cerca`.
- **Audit trail**: ogni inserimento e modifica aggiorna `DataIns`/`UtenteIns` e
  `DataAgg`/`UtenteAgg` automaticamente.

---

## Campi dell'Oggetto

| Campo | Tipo Oracle | Colonna DB | Note |
|-------|-------------|------------|------|
| `IdUtente` | `NUMBER` | `ID_UTENTE` | PK, generato da sequenza |
| `Login` | `VARCHAR2(100)` | `LOGIN` | Identificativo di accesso univoco |
| `Password0` | `VARCHAR2(32)` | `PASSWORD_0` | Hash MD5 password corrente |
| `Password1` | `VARCHAR2(32)` | `PASSWORD_1` | Hash MD5 password precedente |
| `Password2` | `VARCHAR2(32)` | `PASSWORD_2` | Hash MD5 penultima password |
| `Cognome` | `VARCHAR2(50)` | `COGNOME` | |
| `Nome` | `VARCHAR2(50)` | `NOME` | |
| `CodiceFiscale` | `VARCHAR2(16)` | `CODICE_FISCALE` | Dato personale (GDPR) |
| `Telefono` | `VARCHAR2(20)` | `TELEFONO` | Dato personale (GDPR) |
| `Cellulare` | `VARCHAR2(20)` | `CELLULARE` | Dato personale (GDPR) |
| `Fax` | `VARCHAR2(20)` | `FAX` | |
| `Email` | `VARCHAR2(100)` | `EMAIL` | Dato personale (GDPR) |
| `Attivo` | `VARCHAR2(1)` | `ATTIVO` | `'S'` = attivo, `'N'` = disattivato (soft delete) |
| `DataScadenzaPassword` | `DATE` | `DATA_SCADENZA_PASSWORD` | |
| `DataUltimoAccesso` | `DATE` | `DATA_ULTIMO_ACCESSO` | |
| `DataIns` | `DATE` | `DATAINS` | Popolato automaticamente da `Crea` |
| `UtenteIns` | `NUMBER` | `UTENTEI NS` | ID utente che ha creato il record |
| `DataAgg` | `DATE` | `DATAAGG` | Popolato automaticamente da `Crea` e `Modifica` |
| `UtenteAgg` | `NUMBER` | `UTENTEAGG` | ID utente che ha effettuato l'ultima modifica |
| `Annotazioni` | `VARCHAR2(2048)` | `ANNOTAZIONI` | Note libere |
| `IdProfessione` | `NUMBER(9)` | `ID_PROFESSIONE` | FK verso tabella professioni |
| `Incarico` | `VARCHAR2(50)` | `INCARICO` | |
| `Esito` | `OBJ_Esito` | — | Ereditato da `OBJ_Profilatore`; contiene l'esito dell'ultima operazione |

---

## Sinonimi Supportati da BuildWhere

Il metodo `RisolviSinonimo` traduce i nomi logici usati nei contesti applicativi
`CTX_APP_ABL` e `CTX_APP_FLT` nelle colonne fisiche della tabella `UTENTI`.

| Nome logico (contesto) | Colonna fisica | Tipo |
|------------------------|----------------|------|
| `ID_UTENTE` | `ID_UTENTE` | `N` (NUMBER) |
| `LOGIN` | `LOGIN` | `V` (VARCHAR2) |
| `COGNOME` | `COGNOME` | `V` (VARCHAR2) |
| `NOME` | `NOME` | `V` (VARCHAR2) |
| `CODICE_FISCALE` | `CODICE_FISCALE` | `V` (VARCHAR2) |
| `EMAIL` | `EMAIL` | `V` (VARCHAR2) |
| `TELEFONO` | `TELEFONO` | `V` (VARCHAR2) |
| `CELLULARE` | `CELLULARE` | `V` (VARCHAR2) |
| `ATTIVO` | `ATTIVO` | `V` (VARCHAR2) |
| `ID_PROFESSIONE` | `ID_PROFESSIONE` | `N` (NUMBER) |
| `INCARICO` | `INCARICO` | `V` (VARCHAR2) |

Qualsiasi nome logico non presente nella tabella sopra viene ignorato silenziosamente
(non genera errore). Un sinonimo non mappato che proviene da `CTX_APP_FLT` produce
invece un errore 400 tramite `BuildWhere`.

---

## Metodi

### `CONSTRUCTOR FUNCTION OBJ_Utente`

Inizializza tutti i campi a `NULL`. Deve essere chiamato prima di popolare
i campi dell'oggetto per le operazioni di `Crea`.

```plsql
-- Esempio: creazione di un nuovo utente
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente         := OBJ_Utente();
  vUtente.Login   := 'mario.rossi';
  vUtente.Cognome := 'Rossi';
  vUtente.Nome    := 'Mario';
  vUtente.Crea;
  DBMS_OUTPUT.PUT_LINE(vUtente.Esito.StatusCode || ' - ' || vUtente.Esito.Messaggio);
END;
```

---

### `OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2`

Restituisce la stringa identificativa del tipo: `'UTENTE'`.
Usato internamente dal sistema di logging e da `PKG_APP.VerificaAccesso`.

**Ritorno**: `'UTENTE'`

---

### `OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2`

Traduce un nome logico di attributo nella coppia `COLONNA|TIPO` usata da `BuildWhere`.
Viene chiamato internamente da `BuildWhere` durante la costruzione della WHERE clause.

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `pSinonimo` | `VARCHAR2` | Nome logico dell'attributo (es. `'COGNOME'`) |

**Ritorno**: stringa nel formato `'COLONNA|TIPO'` (es. `'COGNOME|V'`), oppure `NULL`
se il sinonimo non è mappato per questo tipo.

Non deve essere chiamato direttamente; viene invocato da `BuildWhere`.

---

### `MEMBER FUNCTION ControlliLogici RETURN BOOLEAN`

Esegue le validazioni di integrità logica sull'oggetto prima delle operazioni di
`Crea` e `Modifica`. Nella versione corrente restituisce sempre `TRUE` (nessun
controllo applicativo configurato).

**Ritorno**: `TRUE` se l'oggetto è valido, `FALSE` in caso contrario.

Passare come quarto parametro a `PKG_APP.VerificaAccesso` nei metodi `Crea` e
`Modifica`:

```plsql
vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'UTENTE', NULL, SELF.ControlliLogici());
```

---

### `MEMBER PROCEDURE Crea`

Inserisce un nuovo record in `UTENTI`. Prima di eseguire l'INSERT verifica che la
sessione abbia il privilegio `INSERIMENTO` sull'oggetto `UTENTE` tramite
`PKG_APP.VerificaAccesso`.

Campi popolati automaticamente:
- `IdUtente` — generato da `UTENTI_ID_UTENTE.NEXTVAL`
- `Attivo` — impostato a `'S'`
- `DataIns`, `UtenteIns` — impostati a `SYSDATE` e `MioIdUtente()`
- `DataAgg`, `UtenteAgg` — impostati a `SYSDATE` e `MioIdUtente()`

**Esito dopo la chiamata**:

| StatusCode | Significato |
|------------|-------------|
| 200 | Utente creato correttamente |
| 401 | Sessione non attiva o privilegio mancante |
| 400 | Controlli logici falliti |
| 500 | Errore interno (es. violazione di vincolo univoco su `LOGIN`) |

```plsql
-- Esempio
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente         := OBJ_Utente();
  vUtente.Login   := 'luigi.bianchi';
  vUtente.Cognome := 'Bianchi';
  vUtente.Nome    := 'Luigi';
  vUtente.Email   := 'luigi.bianchi@asl.it';
  vUtente.Crea;
  IF vUtente.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Creato con IdUtente = ' || vUtente.IdUtente);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vUtente.Esito.Messaggio);
  END IF;
END;
```

---

### `MEMBER PROCEDURE Modifica`

Aggiorna il record in `UTENTI` identificato da `SELF.IdUtente`. Verifica il
privilegio `MODIFICA` tramite `PKG_APP.VerificaAccesso`. Aggiorna automaticamente
`DataAgg` e `UtenteAgg`.

**Esito dopo la chiamata**:

| StatusCode | Significato |
|------------|-------------|
| 200 | Utente modificato correttamente |
| 404 | Nessun record trovato con `IdUtente` specificato |
| 401 | Sessione non attiva o privilegio mancante |
| 400 | Controlli logici falliti |
| 500 | Errore interno |

```plsql
-- Esempio: modifica del cognome
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente := OBJ_Utente.Carica(237);
  IF vUtente.Esito.StatusCode = 200 THEN
    vUtente.Cognome := 'Nuovo Cognome';
    vUtente.Modifica;
    DBMS_OUTPUT.PUT_LINE(vUtente.Esito.StatusCode || ' - ' || vUtente.Esito.Messaggio);
  END IF;
END;
```

---

### `MEMBER PROCEDURE Elimina(pFisica BOOLEAN DEFAULT FALSE)`

Elimina l'utente identificato da `SELF.IdUtente`. Verifica il privilegio
`ELIMINAZIONE` tramite `PKG_APP.VerificaAccesso`. Il comportamento dipende dal
parametro `pFisica`:

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `pFisica` | `BOOLEAN` | `FALSE` | Se `FALSE`: soft delete (`Attivo = 'N'`). Se `TRUE`: cancellazione fisica della riga. |

**Esito dopo la chiamata**:

| StatusCode | Significato |
|------------|-------------|
| 200 | Eliminazione eseguita correttamente |
| 404 | Nessun record trovato con `IdUtente` specificato |
| 401 | Sessione non attiva o privilegio mancante |
| 500 | Errore interno |

```plsql
-- Soft delete (default)
vUtente.Elimina;

-- Cancellazione fisica
vUtente.Elimina(TRUE);
```

**Nota**: i controlli logici non vengono eseguiti in `Elimina`; il quarto parametro
di `VerificaAccesso` è sempre `TRUE`.

---

### `STATIC FUNCTION Carica(pIdUtente NUMBER) RETURN OBJ_Utente`

Carica un utente dal database dato il suo `ID_UTENTE`. Richiede che la sessione
sia attiva (`MioIdRuolo() IS NOT NULL`). Non chiama `VerificaAccesso`: viene usato
anche da `PKG_APP.Inizializza` prima che il contesto sia completamente popolato.

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `pIdUtente` | `NUMBER` | Chiave primaria dell'utente da caricare |

**Ritorno**: istanza di `OBJ_Utente` con tutti i campi popolati dal DB, o con
`Esito.StatusCode` non 200 in caso di errore.

**Esito dell'oggetto restituito**:

| StatusCode | Significato |
|------------|-------------|
| 200 | Utente caricato correttamente |
| 204 | Utente non trovato (nessuna riga per `pIdUtente`) |
| 401 | Sessione non attiva (`MioIdRuolo() IS NULL`) |
| 500 | Errore interno |

```plsql
-- Esempio
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente := OBJ_Utente.Carica(237);
  IF vUtente.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE(vUtente.Cognome || ' ' || vUtente.Nome);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Non trovato: ' || vUtente.Esito.Messaggio);
  END IF;
END;
```

**Attenzione**: il metodo recupera anche i campi `Password_0/1/2` (hash MD5).
Non esporre questi valori nelle API REST senza un'esplicita necessità.

---

### `MEMBER PROCEDURE Cerca(pCursor OUT SYS_REFCURSOR)`

Esegue una ricerca sugli utenti combinando automaticamente:

- I filtri di **autorizzazione** (`CTX_APP_ABL`) — caricati da `PKG_APP.Inizializza`
  e applicati sempre, limitando la visibilità ai dati del profilo corrente.
- I filtri di **ricerca** (`CTX_APP_FLT`) — impostati dal chiamante a runtime
  tramite `PKG_APP.AggiungiContesto`.

La WHERE clause viene costruita dinamicamente tramite `BuildWhere` (ereditato da
`OBJ_Profilatore`) con alias tabella `'U'`.

**Parametro di output**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `pCursor` | `SYS_REFCURSOR OUT` | Cursore sulla query risultante. `NULL` in caso di errore. |

**Colonne restituite dal cursore**:

| Colonna | Tipo | Descrizione |
|---------|------|-------------|
| `Id_Utente` | `NUMBER` | Chiave primaria |
| `Login` | `VARCHAR2(100)` | Identificativo di accesso |
| `Cognome` | `VARCHAR2(50)` | Cognome dell'utente |
| `Nome` | `VARCHAR2(50)` | Nome dell'utente |
| `Email` | `VARCHAR2(100)` | Indirizzo email |
| `Attivo` | `VARCHAR2(1)` | `'S'` = attivo, `'N'` = disattivato |

**Colonne volutamente escluse**: `Password_0/1/2` (hash MD5) e tutti i campi di audit.

**Ordinamento**: `Cognome ASC, Nome ASC`.

**Esito dopo la chiamata** (`SELF.Esito.StatusCode`):

| StatusCode | Significato | Azione del chiamante |
|------------|-------------|----------------------|
| 200 | Cursore aperto correttamente | Iterare con `FETCH`, chiudere con `CLOSE` |
| 401 | Sessione non attiva (`MioIdRuolo() IS NULL`) | `pCursor` è `NULL`, non usarlo |
| 400 | Errore nei filtri (`BuildWhere` fallita) | `pCursor` è `NULL`, leggere `SELF.Esito.Messaggio` |
| 500 | Errore interno Oracle | `pCursor` è `NULL` |

**Avvisi BuildWhere**: se la combinazione di `CTX_APP_ABL` e `CTX_APP_FLT` allarga
la visibilità autorizzata (es. un filtro di ricerca include valori non presenti nel
profilo), `SELF.Esito.DebugInfo` contiene un messaggio di avviso. Il cursore viene
comunque aperto (StatusCode 200).

#### Esempio di utilizzo

```plsql
DECLARE
  vUtente   OBJ_Utente;
  vCursor   SYS_REFCURSOR;
  vIdUtente NUMBER;
  vLogin    VARCHAR2(100);
  vCognome  VARCHAR2(50);
  vNome     VARCHAR2(50);
  vEmail    VARCHAR2(100);
  vAttivo   VARCHAR2(1);
BEGIN
  -- Impostare il filtro di ricerca prima di chiamare Cerca
  PKG_APP.PulisciContesto('CTX_APP_FLT');
  PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'SA%|LIKE');

  vUtente := OBJ_Utente();
  vUtente.Cerca(vCursor);

  IF vUtente.Esito.StatusCode = 200 THEN
    LOOP
      FETCH vCursor INTO vIdUtente, vLogin, vCognome, vNome, vEmail, vAttivo;
      EXIT WHEN vCursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(vIdUtente || ' - ' || vCognome || ' ' || vNome);
    END LOOP;
    CLOSE vCursor;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vUtente.Esito.StatusCode
      || ' - ' || vUtente.Esito.Messaggio);
  END IF;

  PKG_APP.PulisciContesto('CTX_APP_FLT');
END;
```

#### Esempi di filtri supportati

I filtri vengono impostati su `CTX_APP_FLT` nel formato `VALORI|OPERATORE`:

```plsql
-- Cognome che inizia per SA
PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'SA%|LIKE');

-- Solo utenti attivi
PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO', 'S|=');

-- Range di ID
PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ID_UTENTE', '100;500|BETWEEN');

-- Solo utenti con email valorizzata
PKG_APP.AggiungiContesto('CTX_APP_FLT', 'EMAIL', '|NOTNULL');

-- Combinazione: COGNOME LIKE 'SA%' AND ATTIVO = 'S'
PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'SA%|LIKE');
PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO',  'S|=');
```

Per l'elenco completo degli operatori supportati vedere la documentazione di
`OBJ_Profilatore` ([api/obj-profilatore.md](obj-profilatore.md)).

---

## Gestione delle Eccezioni

Tutti i metodi catturano le eccezioni con `WHEN OTHERS` e impostano
`SELF.Esito.StatusCode = 500`. Il messaggio di errore Oracle (`SQLERRM`) viene
incluso nei campi `Errori` e `DebugInfo` dell'esito.

Il chiamante deve sempre controllare `SELF.Esito.StatusCode` prima di usare
l'oggetto o il cursore restituito.

---

## Azioni RBAC Richieste

Per eseguire le operazioni CRUD è necessario che il ruolo dell'utente corrente
abbia un privilegio attivo (`Attivo = 'S'`) per le seguenti azioni sull'oggetto
`'UTENTE'`:

| Metodo | Azione richiesta |
|--------|-----------------|
| `Crea` | `'INSERIMENTO'` |
| `Modifica` | `'MODIFICA'` |
| `Elimina` | `'ELIMINAZIONE'` |
| `Carica` | nessuna (controlla solo `MioIdRuolo() IS NOT NULL`) |
| `Cerca` | nessuna (controlla solo `MioIdRuolo() IS NOT NULL`) |

---

## Script di Test Correlati

| Procedura | Descrizione |
|-----------|-------------|
| `TUT1(pIdUtente)` | CRUD completo: `Carica`, `Crea`, `Modifica`, `Elimina` |
| `TCER1` | Ricerca utenti con `COGNOME LIKE 'SA%'` tramite `Cerca` |
| `TBW1`–`TBW8` | Test unitari di `BuildWhere` (usano `OBJ_Utente` come tipo concreto) |
| `TBWP1(pIterazioni)` | Benchmark di performance `BuildWhere` con tre scenari |

Vedere `SRC/TEST_APP.sql` per il codice completo.

---

## Dipendenze

| Dipendenza | Tipo | Motivo |
|------------|------|--------|
| `OBJ_Profilatore` | Supertipo | Eredita `Esito`, `BuildWhere`, funzioni di sessione |
| `OBJ_Esito` | Tipo Oracle | Usato per tutti i valori di ritorno |
| `PKG_APP.VerificaAccesso` | Package | Controllo RBAC centralizzato per `Crea`, `Modifica`, `Elimina` |
| `PKG_APP.AggiungiContesto` | Package | Impostazione filtri prima di `Cerca` |
| `PKG_APP.PulisciContesto` | Package | Pulizia contesti prima e dopo `Cerca` |
| `UTENTI` | Tabella DB | Tabella fisica degli utenti |
| `UTENTI_ID_UTENTE` | Sequenza DB | Generazione PK in `Crea` |
| `CTX_APP_IDS` | Application Context | Identità sessione corrente |
| `CTX_APP_ABL` | Application Context | Filtri di autorizzazione del profilo |
| `CTX_APP_FLT` | Application Context | Filtri di ricerca impostati a runtime |
