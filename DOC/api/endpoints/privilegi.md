# SISTER — Endpoint: Privilegi

**Entità**: `OBJ_Privilegio`
**Tabella DB**: `TBL_PRIVILEGI`
**Sequenza**: `PRIVILEGI_ID_PRIVILEGIO`
**Azioni RBAC richieste**: `INSERIMENTO/PRIVILEGIO`, `MODIFICA/PRIVILEGIO`, `ELIMINAZIONE/PRIVILEGIO`
**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

Il privilegio è l'elemento che collega un **ruolo** a un'**azione**, autorizzando
gli utenti con quel ruolo a eseguire quell'operazione. Il metodo `Cerca()` è usato
internamente da `PKG_APP.VerificaAccesso()` per verificare se il ruolo corrente
della sessione ha il privilegio necessario.

---

## Campi dell'Entità

| Campo | Tipo Oracle | Tipo JSON | Obbligatorio | Descrizione |
|-------|-------------|-----------|:---:|-------------|
| `IdPrivilegio` | NUMBER | number | (auto) | Chiave primaria, generata da sequenza |
| `IdAzione` | NUMBER | number | SI | FK → TBL_AZIONI.ID_AZIONE |
| `IdRuolo` | NUMBER | number | SI | FK → TAB_RUOLI.ID_RUOLO |
| `DataIns` | DATE | date | (auto) | Data inserimento |
| `UtenteIns` | NUMBER | number | (auto) | Utente che ha creato il record |
| `DataAgg` | DATE | date | (auto) | Data ultima modifica |
| `UtenteAgg` | NUMBER | number | (auto) | Utente che ha modificato il record |
| `Attivo` | VARCHAR2(1) | string | (auto) | 'S' = attivo, 'N' = disattivato |

---

## Endpoint

### POST /sister/privilegi — Crea Privilegio

**Azione RBAC**: `INSERIMENTO / PRIVILEGIO`
**Internamente chiama**: `OBJ_Privilegio.Crea()`

**Body richiesta**:
```json
{
  "id_azione": 10,
  "id_ruolo":  100
}
```

**Risposta successo** (HTTP 200):
```json
{
  "status_code":  200,
  "messaggio":    "Privilegio creato con successo",
  "id_privilegio": 501
}
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vPrivilegio OBJ_Privilegio;
BEGIN
  vPrivilegio := OBJ_Privilegio();
  vPrivilegio.IdAzione := 10;   -- INSERIMENTO/UTENTE
  vPrivilegio.IdRuolo  := 100;  -- Amministratore

  vPrivilegio.Crea();

  IF vPrivilegio.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Privilegio creato: ' || vPrivilegio.IdPrivilegio);
    COMMIT;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vPrivilegio.Esito.Messaggio);
    ROLLBACK;
  END IF;
END;
```

---

### GET /sister/privilegi/{id_privilegio} — Carica Privilegio per ID

**Internamente chiama**: `OBJ_Privilegio.Carica(pIdPrivilegio)`

**Risposta successo** (HTTP 200):
```json
{
  "status_code":  200,
  "messaggio":    "Privilegio caricato con successo",
  "id_privilegio": 501,
  "id_azione":    10,
  "id_ruolo":     100,
  "attivo":       "S"
}
```

---

### GET /sister/privilegi — Cerca Privilegio per coppia Azione/Ruolo

**Internamente chiama**: `OBJ_Privilegio.Carica(pIdAzione, pIdRuolo)`

Usato per verificare se un ruolo ha un certo privilegio (alternativa a `Cerca`
che restituisce solo l'ID).

**Query parameters**:

| Parametro | Tipo | Obbligatorio | Descrizione |
|-----------|------|:---:|-------------|
| `id_azione` | number | SI | ID dell'azione |
| `id_ruolo` | number | SI | ID del ruolo |

**Esempio curl**:
```bash
curl "https://[ORDS_BASE_URL]/sister/privilegi?id_azione=10&id_ruolo=100"
```

**Esempio PL/SQL — Cerca (usato da VerificaAccesso)**:
```plsql
DECLARE
  vIdPrivilegio NUMBER;
BEGIN
  -- Cerca restituisce IdPrivilegio o NULL
  vIdPrivilegio := OBJ_Privilegio.Cerca(10, 100);

  IF vIdPrivilegio IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('Privilegio attivo: ' || vIdPrivilegio);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Ruolo 100 non ha il privilegio per azione 10');
  END IF;
END;
```

---

### PUT /sister/privilegi/{id_privilegio} — Modifica Privilegio

**Azione RBAC**: `MODIFICA / PRIVILEGIO`
**Internamente chiama**: `OBJ_Privilegio.Modifica()`

Campi aggiornabili: `IdAzione`, `IdRuolo`, `Attivo`.

---

### DELETE /sister/privilegi/{id_privilegio} — Elimina Privilegio

**Azione RBAC**: `ELIMINAZIONE / PRIVILEGIO`
**Internamente chiama**: `OBJ_Privilegio.Elimina(pFisica)`

Per default esegue soft delete (`ATTIVO='N'`).

**Esempio PL/SQL — soft delete**:
```plsql
DECLARE
  vPrivilegio OBJ_Privilegio;
BEGIN
  vPrivilegio := OBJ_Privilegio();
  vPrivilegio.IdPrivilegio := 501;
  vPrivilegio.Elimina();         -- soft delete

  IF vPrivilegio.Esito.StatusCode = 200 THEN
    COMMIT;
  END IF;
END;
```

**Esempio PL/SQL — cancellazione fisica**:
```plsql
DECLARE
  vPrivilegio OBJ_Privilegio;
BEGIN
  vPrivilegio := OBJ_Privilegio();
  vPrivilegio.IdPrivilegio := 501;
  vPrivilegio.Elimina(pFisica => TRUE);  -- cancellazione fisica

  IF vPrivilegio.Esito.StatusCode = 200 THEN
    COMMIT;
  END IF;
END;
```

---

## Metodo RisolviSinonimo (per BuildWhere)

| Sinonimo | Colonna | Tipo |
|----------|---------|------|
| `ID_PRIVILEGIO` | `ID_PRIVILEGIO` | N (NUMBER) |
| `ID_AZIONE` | `ID_AZIONE` | N |
| `ID_RUOLO` | `ID_RUOLO` | N |
| `ATTIVO` | `ATTIVO` | V (VARCHAR) |

---

[← Azioni](azioni.md) | [← Torna all'indice](../../README.md) | [Abilitazioni →](abilitazioni.md)
