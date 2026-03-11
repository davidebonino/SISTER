# SISTER — Endpoint: Utenti

**Entità**: `OBJ_Utente`
**Tabella DB**: `UTENTI`
**Sequenza**: `UTENTI_ID_UTENTE`
**Azioni RBAC richieste**: `INSERIMENTO/UTENTE`, `MODIFICA/UTENTE`, `ELIMINAZIONE/UTENTE`
**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

L'utente è l'entità centrale del sistema. Ogni utente può avere più profili
(associazioni con ruoli diversi). La libreria implementa CRUD completo con
soft delete (impostazione `ATTIVO='N'`) e audit trail completo.

---

## Campi dell'Entità

| Campo | Tipo Oracle | Tipo JSON | Obbligatorio | Descrizione |
|-------|-------------|-----------|:---:|-------------|
| `IdUtente` | NUMBER | number | (auto) | Chiave primaria, generata da sequenza |
| `Login` | VARCHAR2(100) | string | SI | Username univoco per accesso al sistema |
| `Password0` | VARCHAR2(32) | string | SI | Hash MD5 password corrente |
| `Password1` | VARCHAR2(32) | string | NO | Hash MD5 password precedente (storico) |
| `Password2` | VARCHAR2(32) | string | NO | Hash MD5 penultima password (storico) |
| `Cognome` | VARCHAR2(50) | string | SI | Cognome utente |
| `Nome` | VARCHAR2(50) | string | NO | Nome utente |
| `CodiceFiscale` | VARCHAR2(16) | string | NO | Codice fiscale (dato sensibile GDPR) |
| `Telefono` | VARCHAR2(20) | string | NO | Telefono fisso (dato sensibile GDPR) |
| `Cellulare` | VARCHAR2(20) | string | NO | Cellulare (dato sensibile GDPR) |
| `Fax` | VARCHAR2(20) | string | NO | Fax |
| `Email` | VARCHAR2(100) | string | NO | Email (dato sensibile GDPR) |
| `Attivo` | VARCHAR2(1) | string | (auto) | 'S' = attivo, 'N' = disattivato |
| `DataScadenzaPassword` | DATE | date | NO | Scadenza password (YYYY-MM-DD) |
| `DataUltimoAccesso` | DATE | date | (auto) | Ultimo accesso al sistema |
| `DataIns` | DATE | date | (auto) | Data inserimento record |
| `UtenteIns` | NUMBER | number | (auto) | ID utente che ha creato il record |
| `DataAgg` | DATE | date | (auto) | Data ultima modifica |
| `UtenteAgg` | NUMBER | number | (auto) | ID utente che ha modificato il record |
| `Annotazioni` | VARCHAR2(2048) | string | NO | Note libere |
| `IdProfessione` | NUMBER(9) | number | NO | ID professione (FK esterna) |
| `Incarico` | VARCHAR2(50) | string | NO | Incarico o ruolo organizzativo |

> **Nota GDPR**: i campi `CodiceFiscale`, `Telefono`, `Cellulare`, `Email`
> contengono dati personali identificativi. Trattarli nel rispetto della
> normativa GDPR (minimizzazione, controllo accessi, cifratura in transit).

---

## Endpoint

### POST /sister/utenti — Crea Utente

**Azione RBAC**: `INSERIMENTO / UTENTE`
**Internamente chiama**: `OBJ_Utente.Crea()`

**Body richiesta**:
```json
{
  "login":                    "mario.rossi",
  "password0":                "5f4dcc3b5aa765d61d8327deb882cf99",
  "cognome":                  "Rossi",
  "nome":                     "Mario",
  "email":                    "mario.rossi@example.com",
  "data_scadenza_password":   "2027-03-11"
}
```

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Utente creato con successo",
  "id_utente":   8501
}
```

**Risposta errori**:

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 401 | `Utente non inserimento, autenticazione mancante` | Sessione non inizializzata |
| 401 | `Utente non inserimento, privilegi insufficienti` | Ruolo senza privilegio INSERIMENTO/UTENTE |
| 400 | `Utente non inserimento, errori nei controlli logici` | Validazioni business fallite |
| 500 | `Utente non inserito per errore interno` | Errore Oracle (es. violazione UNIQUE su Login) |

**Esempio curl**:
```bash
curl -X POST https://[ORDS_BASE_URL]/sister/utenti \
  -H "Content-Type: application/json" \
  -d '{
    "login":   "mario.rossi",
    "cognome": "Rossi",
    "nome":    "Mario",
    "email":   "mario.rossi@example.com"
  }'
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente := OBJ_Utente();
  vUtente.Login   := 'mario.rossi';
  vUtente.Cognome := 'Rossi';
  vUtente.Nome    := 'Mario';
  vUtente.Email   := 'mario.rossi@example.com';

  vUtente.Crea();

  IF vUtente.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Creato con IdUtente: ' || vUtente.IdUtente);
    COMMIT;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vUtente.Esito.Messaggio);
    ROLLBACK;
  END IF;
END;
```

---

### GET /sister/utenti/{id_utente} — Carica Utente

**Internamente chiama**: `OBJ_Utente.Carica(pIdUtente)`
Richiede sessione attiva (`MioIdRuolo() IS NOT NULL`).

**Parametri URL**:

| Parametro | Tipo | Obbligatorio | Descrizione |
|-----------|------|:---:|-------------|
| `id_utente` | number | SI | Identificatore numerico utente |

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Utente caricato con successo",
  "id_utente":   8501,
  "login":       "mario.rossi",
  "cognome":     "Rossi",
  "nome":        "Mario",
  "email":       "mario.rossi@example.com",
  "attivo":      "S",
  "data_ultimo_accesso": "2026-03-10T14:22:00"
}
```

**Risposta errori**:

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 401 | `Chiamante non autorizzato` | Sessione non inizializzata |
| 204 | `Utente non trovato` | IdUtente non esistente in UTENTI |
| 500 | `Utente non trovato per errore interno` | Errore Oracle imprevisto |

---

### PUT /sister/utenti/{id_utente} — Modifica Utente

**Azione RBAC**: `MODIFICA / UTENTE`
**Internamente chiama**: `OBJ_Utente.Modifica()`

Aggiorna tutti i campi modificabili. I campi `IdUtente`, `DataIns`, `UtenteIns`
e `Attivo` non vengono aggiornati da questo metodo.

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Utente modificato con successo"
}
```

**Risposta errori**:

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 404 | `Utente non trovato per modifica` | UPDATE con 0 righe aggiornate |
| 401 | Vari | Sessione non attiva o privilegio mancante |
| 500 | `Utente non modificato per errore interno` | Errore Oracle imprevisto |

---

### DELETE /sister/utenti/{id_utente} — Elimina Utente

**Azione RBAC**: `ELIMINAZIONE / UTENTE`
**Internamente chiama**: `OBJ_Utente.Elimina(pFisica)`

Per default esegue soft delete (`ATTIVO='N'`). La cancellazione fisica
richiede il parametro `fisica=true` nella query string.

**Parametri URL**:

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `id_utente` | number | — | Identificatore utente |
| `fisica` | boolean | false | `true` = cancellazione fisica; `false` = soft delete |

**Esempio soft delete** (default):
```bash
curl -X DELETE "https://[ORDS_BASE_URL]/sister/utenti/8501"
```

**Esempio cancellazione fisica**:
```bash
curl -X DELETE "https://[ORDS_BASE_URL]/sister/utenti/8501?fisica=true"
```

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Utente eliminato con successo"
}
```

**Esempio PL/SQL — soft delete**:
```plsql
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente := OBJ_Utente();
  vUtente.IdUtente := 8501;
  vUtente.Elimina();   -- soft delete (Attivo = 'N')

  IF vUtente.Esito.StatusCode = 200 THEN
    COMMIT;
  END IF;
END;
```

**Esempio PL/SQL — cancellazione fisica**:
```plsql
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente := OBJ_Utente();
  vUtente.IdUtente := 8501;
  vUtente.Elimina(pFisica => TRUE);   -- cancellazione fisica

  IF vUtente.Esito.StatusCode = 200 THEN
    COMMIT;
  END IF;
END;
```

---

## Metodo RisolviSinonimo (per BuildWhere)

`OBJ_Utente.RisolviSinonimo()` mappa i nomi logici ai campi fisici della tabella `UTENTI`:

| Sinonimo | Colonna | Tipo |
|----------|---------|------|
| `ID_UTENTE` | `ID_UTENTE` | N (NUMBER) |
| `LOGIN` | `LOGIN` | V (VARCHAR) |
| `COGNOME` | `COGNOME` | V |
| `NOME` | `NOME` | V |
| `CODICE_FISCALE` | `CODICE_FISCALE` | V |
| `EMAIL` | `EMAIL` | V |
| `TELEFONO` | `TELEFONO` | V |
| `CELLULARE` | `CELLULARE` | V |
| `ATTIVO` | `ATTIVO` | V |
| `ID_PROFESSIONE` | `ID_PROFESSIONE` | N |
| `INCARICO` | `INCARICO` | V |

---

[← Sessioni](sessioni.md) | [← Torna all'indice](../../README.md) | [Profili →](profili.md)
