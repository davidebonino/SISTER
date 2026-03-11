# SISTER — Endpoint: Profili

**Entità**: `OBJ_Profilo`
**Tabella DB**: `PROFILI`
**Sequenza**: `PROFILI_ID_PROFILO`
**Azioni RBAC richieste**: `INSERIMENTO/PROFILO`, `MODIFICA/PROFILO`, `ELIMINAZIONE/PROFILO`
**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

Il profilo rappresenta la combinazione utente-ruolo che definisce il contesto
di lavoro nel sistema. Un utente può avere più profili attivi (es. un profilo
da amministratore e uno da operatore); al login viene selezionato un profilo specifico.

Il metodo speciale `CaricaContestoAbilitazioni()` popola il contesto Oracle
`CTX_APP_ABL` con i filtri di visibilità associati al profilo, usati poi
da `BuildWhere()` per filtrare automaticamente i risultati delle query.

---

## Campi dell'Entità

| Campo | Tipo Oracle | Tipo JSON | Obbligatorio | Descrizione |
|-------|-------------|-----------|:---:|-------------|
| `IdProfilo` | NUMBER | number | (auto) | Chiave primaria, generata da sequenza |
| `IdUtente` | NUMBER | number | SI | FK → UTENTI.ID_UTENTE |
| `IdRuolo` | NUMBER | number | SI | FK → TAB_RUOLI.ID_RUOLO |
| `Nome` | VARCHAR2(80) | string | SI | Nome descrittivo del profilo |
| `DataIns` | DATE | date | (auto) | Data inserimento |
| `UtenteIns` | NUMBER | number | (auto) | Utente che ha creato il record |
| `DataAgg` | DATE | date | (auto) | Data ultima modifica |
| `UtenteAgg` | NUMBER | number | (auto) | Utente che ha modificato il record |
| `Attivo` | VARCHAR2(1) | string | (auto) | 'S' = attivo, 'N' = disattivato |

---

## Endpoint

### POST /sister/profili — Crea Profilo

**Azione RBAC**: `INSERIMENTO / PROFILO`
**Internamente chiama**: `OBJ_Profilo.Crea()`

**Body richiesta**:
```json
{
  "id_utente": 8501,
  "id_ruolo":  100,
  "nome":      "Operatore Distretto CN1"
}
```

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Profilo creato con successo",
  "id_profilo":  17461
}
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vProfilo OBJ_Profilo;
BEGIN
  vProfilo := OBJ_Profilo();
  vProfilo.IdUtente := 8501;
  vProfilo.IdRuolo  := 100;
  vProfilo.Nome     := 'Operatore Distretto CN1';

  vProfilo.Crea();

  IF vProfilo.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Creato IdProfilo: ' || vProfilo.IdProfilo);
    COMMIT;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vProfilo.Esito.Messaggio);
    ROLLBACK;
  END IF;
END;
```

---

### GET /sister/profili/{id_profilo} — Carica Profilo

**Internamente chiama**: `OBJ_Profilo.Carica(pIdProfilo)`
Richiede sessione attiva (`MioIdRuolo() IS NOT NULL`).

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Profilo caricato con successo",
  "id_profilo":  17460,
  "id_utente":   237,
  "id_ruolo":    100,
  "nome":        "Amministratore Sistema",
  "attivo":      "S"
}
```

---

### PUT /sister/profili/{id_profilo} — Modifica Profilo

**Azione RBAC**: `MODIFICA / PROFILO`
**Internamente chiama**: `OBJ_Profilo.Modifica()`

I campi aggiornabili sono: `IdUtente`, `IdRuolo`, `Nome`, `Attivo`.
I campi di audit (`DataAgg`, `UtenteAgg`) vengono aggiornati automaticamente.

---

### DELETE /sister/profili/{id_profilo} — Elimina Profilo

**Azione RBAC**: `ELIMINAZIONE / PROFILO`
**Internamente chiama**: `OBJ_Profilo.Elimina(pFisica)`

Per default esegue soft delete (`ATTIVO='N'`).

---

### POST /sister/profili/{id_profilo}/abilitazioni/carica — Carica Contesto Abilitazioni

Operazione speciale: carica le abilitazioni del profilo nel contesto Oracle
`CTX_APP_ABL`. Questa operazione viene eseguita automaticamente da
`PKG_APP.Inizializza()` durante il login; è necessario richiamarla
esplicitamente solo in scenari particolari (es. cambio profilo senza nuovo login).

**Internamente chiama**: `OBJ_Profilo.CaricaContestoAbilitazioni(pIdProfilo)`

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Contesto abilitazioni caricato",
  "num_abilitazioni": 5
}
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vNum NUMBER;
BEGIN
  -- Carica manualmente il contesto abilitazioni per il profilo 17460
  vNum := OBJ_Profilo.CaricaContestoAbilitazioni(17460);
  DBMS_OUTPUT.PUT_LINE('Abilitazioni caricate: ' || NVL(TO_CHAR(vNum), '0'));

  -- Verifica il contesto ABL
  DBMS_OUTPUT.PUT_LINE(PKG_APP.VisualizzaContesto('CTX_APP_ABL'));
END;
```

---

## Metodo RisolviSinonimo (per BuildWhere)

| Sinonimo | Colonna | Tipo |
|----------|---------|------|
| `ID_PROFILO` | `ID_PROFILO` | N (NUMBER) |
| `ID_UTENTE` | `ID_UTENTE` | N |
| `ID_RUOLO` | `ID_RUOLO` | N |
| `NOME` | `NOME` | V (VARCHAR) |
| `ATTIVO` | `ATTIVO` | V |

---

[← Utenti](utenti.md) | [← Torna all'indice](../../README.md) | [Azioni →](azioni.md)
