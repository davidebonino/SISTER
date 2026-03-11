# SISTER — Autenticazione e Gestione Sessione

**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

L'autenticazione in SISTER avviene tramite `PKG_APP.Inizializza()`, che:
1. Valida le credenziali dell'utente
2. Crea una sessione in `TBL_SESSIONI`
3. Popola i contesti Oracle (`CTX_APP_IDS`, `CTX_APP_ABL`)
4. Abilita tutti i successivi controlli RBAC

La sessione non ha scadenza automatica. È responsabilità del client gestire
la durata della sessione e chiamare la procedura di logout quando opportuno.

---

## Flusso di Autenticazione

```
PKG_APP.Inizializza(pUsername, pKeyword, pIdProfilo)
  │
  ├─ Reset parametri sistema (CTX_APP_PAR):
  │    DEBUG_LEVEL=0, DEBUG_ENABLED='N', LOG_CONTATORE=0
  │
  ├─ OBJ_Sessione.Crea(pUsername, pKeyword, pIdProfilo)
  │    ├─ JOIN UTENTI-PROFILI con:
  │    │    UPPER(LOGIN) = UPPER(pUsername)
  │    │    PASSWORD_0   = STANDARD_HASH(pKeyword, 'MD5')
  │    │    ATTIVO       = 'S'  (utente e profilo)
  │    │    ID_PROFILO   = pIdProfilo
  │    │    DATA_SCADENZA_PASSWORD >= SYSDATE
  │    ├─ Genera IdSessione con SYS_GUID()
  │    ├─ INSERT INTO TBL_SESSIONI
  │    ├─ COMMIT
  │    └─ Restituisce OBJ_Sessione (Esito.StatusCode = 201)
  │
  ├─ AggiungiContesto('CTX_APP_IDS', 'ID_SESSIONE', ...)
  ├─ AggiungiContesto('CTX_APP_IDS', 'ID_PROFILO',  ...)
  ├─ AggiungiContesto('CTX_APP_IDS', 'ID_RUOLO',    ...)
  │
  ├─ OBJ_Profilo.Carica(idProfilo)
  │    └─ SELECT da PROFILI WHERE ID_PROFILO = pIdProfilo
  │
  ├─ OBJ_Profilo.CaricaContestoAbilitazioni(idProfilo)
  │    ├─ PulisciContesto('CTX_APP_ABL')
  │    ├─ SELECT da ABILITAZIONI GROUP BY CHIAVE, OPERATORE
  │    └─ AggiungiContesto('CTX_APP_ABL', chiave, 'valori|operatore')
  │
  └─ OBJ_Utente.Carica(idUtente)
       ├─ SELECT da UTENTI WHERE ID_UTENTE = pIdUtente
       └─ AggiungiContesto('CTX_APP_IDS', 'ID_UTENTE', ...)
```

---

## Utilizzo PL/SQL

### Login

```plsql
DECLARE
  vOk BOOLEAN;
BEGIN
  vOk := PKG_APP.Inizializza(
    pUsername  => 'mario.rossi',
    pKeyword   => 'Password123',
    pIdProfilo => 17460
  );

  IF vOk THEN
    DBMS_OUTPUT.PUT_LINE('Login OK');
    DBMS_OUTPUT.PUT_LINE('ID_SESSIONE: ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE'));
    DBMS_OUTPUT.PUT_LINE('ID_UTENTE:   ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE'));
    DBMS_OUTPUT.PUT_LINE('ID_RUOLO:    ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO'));
  ELSE
    DBMS_OUTPUT.PUT_LINE('Login FALLITO');
  END IF;
END;
```

### Verifica sessione attiva

```plsql
DECLARE
  vIdRuolo NUMBER;
BEGIN
  vIdRuolo := OBJ_Profilatore.MioIdRuolo();
  IF vIdRuolo IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Sessione non attiva');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Sessione attiva - Ruolo: ' || vIdRuolo);
  END IF;
END;
```

### Lettura contesto sessione

```plsql
-- Lettura diretta dei contesti Oracle
SELECT
  SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE') AS id_sessione,
  SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE')   AS id_utente,
  SYS_CONTEXT('CTX_APP_IDS', 'ID_PROFILO')  AS id_profilo,
  SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO')    AS id_ruolo
FROM DUAL;

-- Tramite funzioni del package
SELECT PKG_APP.GetParametro('LOG_CONTATORE') AS log_counter FROM DUAL;
```

---

## Utilizzo via ORDS (REST)

L'endpoint di login viene esposto tramite ORDS come segue.

### POST /sister/sessioni/login

**Descrizione**: Autentica l'utente e inizializza la sessione applicativa.

**Headers richiesti**:
```
Content-Type: application/json
```

**Body della richiesta**:
```json
{
  "username":   "mario.rossi",
  "password":   "Password123",
  "id_profilo": 17460
}
```

**Risposta di successo** (HTTP 201):
```json
{
  "status_code": 201,
  "messaggio":   "Sessione creata con successo",
  "id_sessione": "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4",
  "id_ruolo":    100,
  "id_profilo":  17460
}
```

**Risposta di errore — credenziali non valide** (HTTP 401):
```json
{
  "status_code": 401,
  "messaggio":   "Autenticazione non riuscita, parametri errati",
  "errori":      [{"errore": "ORA-01403: no data found"}]
}
```

**Risposta di errore — password scaduta** (HTTP 401):
```json
{
  "status_code": 401,
  "messaggio":   "Autenticazione non riuscita, parametri errati",
  "errori":      [{"errore": "ORA-01403: no data found"}]
}
```

**Esempio curl**:
```bash
curl -X POST https://[ORDS_BASE_URL]/sister/sessioni/login \
  -H "Content-Type: application/json" \
  -d '{"username":"mario.rossi","password":"Password123","id_profilo":17460}'
```

---

## Struttura della Tabella TBL_SESSIONI

| Colonna | Tipo | Descrizione |
|---------|------|-------------|
| `ID_SESSIONE` | RAW(16) | Identificatore univoco (SYS_GUID) |
| `ID_PROFILO` | NUMBER | Profilo selezionato al login |
| `ID_RUOLO` | NUMBER | Ruolo associato al profilo |
| `STATO` | CHAR(1) | 'A' = Attiva |
| `DATA` | DATE | Timestamp di creazione |

---

## Verifica RBAC nelle Operazioni CRUD

Ogni metodo CRUD chiama `PKG_APP.VerificaAccesso()` prima di qualsiasi operazione:

```plsql
-- Schema standard in ogni metodo Crea/Modifica/Elimina:
vEsitoAccesso := PKG_APP.VerificaAccesso(
  pTipoAzione      => 'INSERIMENTO',  -- tipo operazione
  pOggetto         => 'UTENTE',       -- entità
  pAmbito          => NULL,           -- contesto (NULL = generico)
  pControlliLogici => SELF.ControlliLogici()  -- validazioni business
);
IF vEsitoAccesso.StatusCode <> 200 THEN
  SELF.Esito := vEsitoAccesso;
  RETURN;
END IF;
```

### Tipi di Azione Predefiniti

| Tipo | Descrizione | Usato da |
|------|-------------|----------|
| `INSERIMENTO` | Creazione di un nuovo record | Crea() |
| `MODIFICA` | Aggiornamento record esistente | Modifica() |
| `ELIMINAZIONE` | Cancellazione (soft o fisica) | Elimina() |
| `VISUALIZZAZIONE` | Lettura con verifica accesso | Carica() con privilegio |

---

## Configurazione Application Contexts (Setup Iniziale)

I contesti Oracle devono essere creati una sola volta dall'amministratore DBA:

```sql
-- Eseguire come DBA o utente con privilegi CREATE ANY CONTEXT
CREATE CONTEXT CTX_APP_IDS USING PKG_APP;
CREATE CONTEXT CTX_APP_PAR USING PKG_APP;
CREATE CONTEXT CTX_APP_ABL USING PKG_APP;
CREATE CONTEXT CTX_APP_FLT USING PKG_APP;
CREATE CONTEXT CTX_APP_LOG USING PKG_APP;
```

Oppure tramite il package:

```plsql
BEGIN
  PKG_APP.CreaContesto('CTX_APP_IDS');
  PKG_APP.CreaContesto('CTX_APP_PAR');
  PKG_APP.CreaContesto('CTX_APP_ABL');
  PKG_APP.CreaContesto('CTX_APP_FLT');
  PKG_APP.CreaContesto('CTX_APP_LOG');
END;
```

---

[← Torna all'indice](../README.md) | [Endpoint Sessioni →](endpoints/sessioni.md)
