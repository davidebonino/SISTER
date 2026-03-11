# SISTER — Endpoint: Sessioni

**Entità**: `OBJ_Sessione` / `PKG_APP`
**Tabella DB**: `TBL_SESSIONI`
**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

Le sessioni rappresentano l'accesso autenticato al sistema. Una sessione attiva
è il prerequisito per qualsiasi operazione RBAC. Il token di sessione (`ID_SESSIONE`)
è un RAW(16) generato da `SYS_GUID()`.

---

## Endpoint

### POST /sister/sessioni/login — Crea Sessione (Login)

Autentica l'utente, inizializza il contesto applicativo Oracle e restituisce
il token di sessione.

**Internamente chiama**: `PKG_APP.Inizializza()`

**Parametri richiesta**:

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|:---:|-------------|
| `username` | string | SI | Login utente (case insensitive) |
| `password` | string | SI | Password in chiaro (hashata internamente con MD5) |
| `id_profilo` | number | SI | ID del profilo selezionato dall'utente |

**Body esempio**:
```json
{
  "username":   "mario.rossi",
  "password":   "SecurePass123",
  "id_profilo": 17460
}
```

**Risposta successo** (HTTP 201):
```json
{
  "status_code": 201,
  "messaggio":   "Sessione creata con successo",
  "id_sessione": "A3F2B1C4D5E6A3F2B1C4D5E6A3F2B1C4",
  "id_profilo":  17460,
  "id_ruolo":    100
}
```

**Risposta errori**:

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 401 | `Autenticazione non riuscita, parametri errati` | Credenziali errate o utente/profilo inattivo |
| 401 | `Autenticazione non riuscita, IdRuolo non valido` | Profilo trovato ma senza ruolo valido |
| 500 | `Autenticazione non riuscita per errore interno` | Errore Oracle imprevisto |

**Esempio curl**:
```bash
curl -X POST https://[ORDS_BASE_URL]/sister/sessioni/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "mario.rossi",
    "password": "SecurePass123",
    "id_profilo": 17460
  }'
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vSessione OBJ_Sessione;
BEGIN
  vSessione := OBJ_Sessione.Crea('mario.rossi', 'SecurePass123', 17460);

  IF vSessione.Esito.StatusCode = 201 THEN
    DBMS_OUTPUT.PUT_LINE('Sessione: ' || RAWTOHEX(vSessione.IdSessione));
    DBMS_OUTPUT.PUT_LINE('Ruolo:    ' || vSessione.IdRuolo);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vSessione.Esito.Messaggio);
  END IF;
END;
```

---

### GET /sister/sessioni/{id_sessione} — Carica Sessione

Carica i dati di una sessione esistente per verificarne lo stato.

**Internamente chiama**: `OBJ_Sessione.Carica(pIdSessione)`

**Parametri URL**:

| Parametro | Tipo | Obbligatorio | Descrizione |
|-----------|------|:---:|-------------|
| `id_sessione` | string (hex) | SI | Identificatore sessione in formato HEX (32 caratteri) |

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Sessione caricata con successo",
  "id_sessione": "A3F2B1C4D5E6A3F2B1C4D5E6A3F2B1C4",
  "id_profilo":  17460,
  "id_ruolo":    100,
  "stato":       "A",
  "data":        "2026-03-11T09:30:00"
}
```

**Risposta errori**:

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 204 | `Sessione non trovata, parametri errati` | IdSessione non esistente |
| 500 | `Sessione non trovata per errore interno` | Errore Oracle imprevisto |

**Esempio curl**:
```bash
curl -X GET "https://[ORDS_BASE_URL]/sister/sessioni/A3F2B1C4D5E6A3F2B1C4D5E6A3F2B1C4"
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vSessione OBJ_Sessione;
BEGIN
  vSessione := OBJ_Sessione.Carica('A3F2B1C4D5E6A3F2B1C4D5E6A3F2B1C4');

  IF vSessione.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Stato:     ' || vSessione.Stato);
    DBMS_OUTPUT.PUT_LINE('Data:      ' || TO_CHAR(vSessione.Data, 'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('IdRuolo:   ' || vSessione.IdRuolo);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Non trovata: ' || vSessione.Esito.Messaggio);
  END IF;
END;
```

---

## Schema Tabella TBL_SESSIONI

| Colonna | Tipo Oracle | Descrizione |
|---------|-------------|-------------|
| `ID_SESSIONE` | RAW(16) | Chiave primaria — UUID generato da SYS_GUID() |
| `ID_PROFILO` | NUMBER | FK → PROFILI.ID_PROFILO |
| `ID_RUOLO` | NUMBER | FK → TAB_RUOLI.ID_RUOLO |
| `STATO` | CHAR(1) | 'A' = Attiva |
| `DATA` | DATE | Timestamp di creazione (SYSDATE) |

---

## Note

- La sessione non ha scadenza automatica: il campo `STATO` deve essere aggiornato
  manualmente da una procedura di logout (non ancora implementata in questa versione).
- Il `COMMIT` viene eseguito all'interno di `OBJ_Sessione.Crea()` dopo l'INSERT
  in `TBL_SESSIONI`. Non serve un ulteriore COMMIT dal chiamante per la sessione.
- La password è confrontata come `STANDARD_HASH(pKeyword, 'MD5')`: non viene
  mai esposta in chiaro nel database.

---

[← Torna all'indice](../../README.md) | [Endpoint Utenti →](utenti.md)
