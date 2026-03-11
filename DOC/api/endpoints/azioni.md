# SISTER — Endpoint: Azioni

**Entità**: `OBJ_Azione`
**Tabella DB**: `TBL_AZIONI`
**Sequenza**: `AZIONI_ID_AZIONE`
**Azioni RBAC richieste**: `INSERIMENTO/AZIONE`, `MODIFICA/AZIONE`, `ELIMINAZIONE/AZIONE`
**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

Le azioni costituiscono il catalogo delle operazioni autorizzabili nel sistema RBAC.
Ogni azione è identificata dalla tripla **(Tipo, Oggetto, Ambito)** e rappresenta
un'operazione atomica (es. inserire un utente, visualizzare un profilo).

Prima di poter autorizzare una qualsiasi operazione CRUD su un'entità, è necessario
che esista una riga corrispondente in `TBL_AZIONI` e un privilegio attivo per
il ruolo corrente in `TBL_PRIVILEGI`.

---

## Campi dell'Entità

| Campo | Tipo Oracle | Tipo JSON | Obbligatorio | Descrizione |
|-------|-------------|-----------|:---:|-------------|
| `IdAzione` | NUMBER | number | (auto) | Chiave primaria, generata da sequenza |
| `Tipo` | VARCHAR2(16) | string | SI | Tipo operazione (es. 'INSERIMENTO', 'MODIFICA') |
| `Nome` | VARCHAR2(64) | string | SI | Nome descrittivo dell'azione |
| `Descrizione` | VARCHAR2(256) | string | NO | Descrizione estesa |
| `Oggetto` | VARCHAR2(64) | string | SI | Entità su cui agisce (es. 'UTENTE', 'PROFILO') |
| `Ambito` | VARCHAR2(64) | string | NO | Contesto specializzato (NULL = generico) |
| `DataIns` | DATE | date | (auto) | Data inserimento |
| `UtenteIns` | NUMBER | number | (auto) | Utente che ha creato il record |
| `DataAgg` | DATE | date | (auto) | Data ultima modifica |
| `UtenteAgg` | NUMBER | number | (auto) | Utente che ha modificato il record |

> **Nota**: OBJ_Azione non implementa soft delete. L'eliminazione è sempre fisica.
> Sviluppo futuro: aggiungere il campo `ATTIVO` per allinearsi al pattern standard.

---

## Tipi di Azione Standard

| Tipo | Descrizione |
|------|-------------|
| `INSERIMENTO` | Creazione di un nuovo record |
| `MODIFICA` | Aggiornamento di un record esistente |
| `ELIMINAZIONE` | Cancellazione di un record |
| `VISUALIZZAZIONE` | Lettura di dati con verifica accesso |

---

## Endpoint

### POST /sister/azioni — Crea Azione

**Azione RBAC**: `INSERIMENTO / AZIONE`
**Internamente chiama**: `OBJ_Azione.Crea()`

**Body richiesta**:
```json
{
  "tipo":        "VISUALIZZAZIONE",
  "nome":        "Visualizza Azione",
  "descrizione": "Visualizza i dettagli di un'azione del catalogo",
  "oggetto":     "AZIONE",
  "ambito":      null
}
```

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Azione creata con successo",
  "id_azione":   42
}
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vAzione OBJ_Azione;
BEGIN
  vAzione := OBJ_Azione();
  vAzione.Tipo        := 'INSERIMENTO';
  vAzione.Nome        := 'Crea Utente';
  vAzione.Descrizione := 'Consente la creazione di un nuovo utente';
  vAzione.Oggetto     := 'UTENTE';
  vAzione.Ambito      := NULL;

  vAzione.Crea();

  IF vAzione.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Creata con IdAzione: ' || vAzione.IdAzione);
    COMMIT;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vAzione.Esito.Messaggio);
    ROLLBACK;
  END IF;
END;
```

---

### GET /sister/azioni/{id_azione} — Carica Azione per ID

**Internamente chiama**: `OBJ_Azione.Carica(pIdAzione)`
Richiede sessione attiva (`MioIdRuolo() IS NOT NULL`).

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Azione caricata con successo",
  "id_azione":   10,
  "tipo":        "INSERIMENTO",
  "nome":        "Crea Utente",
  "oggetto":     "UTENTE",
  "ambito":      null
}
```

---

### GET /sister/azioni — Cerca Azione per tripla

Carica l'azione identificata dalla combinazione tipo/oggetto/ambito.

**Internamente chiama**: `OBJ_Azione.Carica(pTipo, pOggetto, pAmbito)`
Non richiede sessione attiva (usato internamente da `PKG_APP.VerificaAccesso`).

**Query parameters**:

| Parametro | Tipo | Obbligatorio | Descrizione |
|-----------|------|:---:|-------------|
| `tipo` | string | NO | Tipo operazione (es. 'INSERIMENTO') |
| `oggetto` | string | NO | Entità (es. 'UTENTE') |
| `ambito` | string | NO | Ambito opzionale |

**Esempio curl**:
```bash
curl "https://[ORDS_BASE_URL]/sister/azioni?tipo=INSERIMENTO&oggetto=UTENTE"
```

**Esempio PL/SQL — Cerca restituisce solo l'ID**:
```plsql
DECLARE
  vIdAzione NUMBER;
BEGIN
  -- Metodo Cerca: restituisce IdAzione o NULL (usato da VerificaAccesso)
  vIdAzione := OBJ_Azione.Cerca('INSERIMENTO', 'UTENTE', NULL);

  IF vIdAzione IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('IdAzione trovato: ' || vIdAzione);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Azione non configurata');
  END IF;
END;
```

---

### PUT /sister/azioni/{id_azione} — Modifica Azione

**Azione RBAC**: `MODIFICA / AZIONE`
**Internamente chiama**: `OBJ_Azione.Modifica()`

Aggiorna: `Tipo`, `Nome`, `Descrizione`, `Oggetto`, `Ambito`.

---

### DELETE /sister/azioni/{id_azione} — Elimina Azione

**Azione RBAC**: `ELIMINAZIONE / AZIONE`
**Internamente chiama**: `OBJ_Azione.Elimina()`

**Attenzione**: eliminazione fisica (DELETE diretto su TBL_AZIONI).
Prima di eliminare un'azione verificare che non esistano privilegi associati
in TBL_PRIVILEGI.

---

## Metodo RisolviSinonimo (per BuildWhere)

| Sinonimo | Colonna | Tipo |
|----------|---------|------|
| `ID_AZIONE` | `ID_AZIONE` | N (NUMBER) |
| `TIPO` | `TIPO` | V (VARCHAR) |
| `NOME` | `NOME` | V |
| `DESCRIZIONE` | `DESCRIZIONE` | V |
| `OGGETTO` | `OGGETTO` | V |
| `AMBITO` | `AMBITO` | V |

---

[← Profili](profili.md) | [← Torna all'indice](../../README.md) | [Privilegi →](privilegi.md)
