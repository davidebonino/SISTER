# SISTER — Endpoint: Abilitazioni

**Entità**: `OBJ_Abilitazione`
**Tabella DB**: `ABILITAZIONI`
**Sequenza**: `ABILITAZIONI_ID_CHIAVE`
**Azioni RBAC richieste**: `INSERIMENTO/ABILITAZIONE`, `MODIFICA/ABILITAZIONE`,
  `ELIMINAZIONE/ABILITAZIONE`, `VISUALIZZAZIONE/ABILITAZIONE`
**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Panoramica

Le abilitazioni sono i filtri di visibilità associati a un profilo utente.
Vengono caricate in `CTX_APP_ABL` durante il login e usate da
`OBJ_Profilatore.BuildWhere()` per limitare automaticamente i risultati
delle query al sottoinsieme di dati accessibile dal profilo.

Una abilitazione definisce: per quale chiave (es. `ATTIVO`), con quale operatore
(es. `=`), quali valori sono accessibili (es. `S;N`).

---

## Campi dell'Entità

| Campo | Tipo Oracle | Tipo JSON | Obbligatorio | Descrizione |
|-------|-------------|-----------|:---:|-------------|
| `IdChiave` | NUMBER | number | (auto) | Chiave primaria, generata da sequenza |
| `IdProfilo` | NUMBER | number | SI | FK → PROFILI.ID_PROFILO |
| `Tipo` | NUMBER | number | NO | Tipo di filtro (uso interno) |
| `Chiave` | VARCHAR2(30) | string | SI | Nome logico del campo filtro (es. 'ATTIVO') |
| `Valore` | VARCHAR2(100) | string | SI | Valore del filtro (es. 'S') |
| `DataIns` | DATE | date | (auto) | Data inserimento |
| `UtenteIns` | NUMBER | number | (auto) | Utente che ha creato il record |
| `DataAgg` | DATE | date | (auto) | Data ultima modifica |
| `UtenteAgg` | NUMBER | number | (auto) | Utente che ha modificato il record |
| `Operatore` | VARCHAR2(3) | string | SI | Operatore SQL (es. '=', '<>', 'LIKE') |

> **Nota**: OBJ_Abilitazione non implementa soft delete (non esiste il campo `ATTIVO`).
> L'eliminazione è sempre fisica. Sviluppo futuro: aggiungere `ATTIVO` per uniformità.

---

## Formato nel Contesto CTX_APP_ABL

Dopo `CaricaContestoAbilitazioni()`, le abilitazioni dello stesso profilo
con la stessa chiave e operatore vengono raggruppate:

```
Chiave: ATTIVO
Valore nel contesto: S;N|=
(valori separati da ; seguiti da | e operatore)
```

`BuildWhere()` interpreta questo formato per costruire la clausola WHERE:
- Un solo valore `S|=` → `ATTIVO = 'S'`
- Più valori `S;N|=` → `ATTIVO IN ('S','N')`
- Operatore LIKE `rossi%|LIKE` → `COGNOME LIKE 'rossi%'`

---

## Endpoint

### POST /sister/abilitazioni — Crea Abilitazione

**Azione RBAC**: `INSERIMENTO / ABILITAZIONE`
**Internamente chiama**: `OBJ_Abilitazione.Crea()`

**Body richiesta**:
```json
{
  "id_profilo": 17460,
  "tipo":       1,
  "chiave":     "ATTIVO",
  "valore":     "S",
  "operatore":  "="
}
```

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Abilitazione creata con successo",
  "id_chiave":   301
}
```

**Esempio PL/SQL**:
```plsql
DECLARE
  vAbilitazione OBJ_Abilitazione;
BEGIN
  vAbilitazione := OBJ_Abilitazione();
  vAbilitazione.IdProfilo := 17460;
  vAbilitazione.Tipo      := 1;
  vAbilitazione.Chiave    := 'ATTIVO';
  vAbilitazione.Valore    := 'S';
  vAbilitazione.Operatore := '=';

  vAbilitazione.Crea();

  IF vAbilitazione.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Creata IdChiave: ' || vAbilitazione.IdChiave);
    COMMIT;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vAbilitazione.Esito.Messaggio);
    ROLLBACK;
  END IF;
END;
```

---

### GET /sister/abilitazioni/{id_chiave} — Carica Abilitazione

**Azione RBAC**: `VISUALIZZAZIONE / ABILITAZIONE`
**Internamente chiama**: `OBJ_Abilitazione.Carica(pIdSessione, pIdAbilitazione)`

Nota: questo endpoint richiede l'ID sessione come header o parametro.

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Abilitazione caricata con successo",
  "id_chiave":   301,
  "id_profilo":  17460,
  "tipo":        1,
  "chiave":      "ATTIVO",
  "valore":      "S",
  "operatore":   "="
}
```

---

### PUT /sister/abilitazioni/{id_chiave} — Modifica Abilitazione

**Azione RBAC**: `MODIFICA / ABILITAZIONE`
**Internamente chiama**: `OBJ_Abilitazione.Modifica()`

Campi aggiornabili: `IdProfilo`, `Tipo`, `Chiave`, `Valore`, `Operatore`.

**Risposta successo** (HTTP 200):
```json
{
  "status_code": 200,
  "messaggio":   "Abilitazione modificata con successo"
}
```

---

### DELETE /sister/abilitazioni/{id_chiave} — Elimina Abilitazione

**Azione RBAC**: `ELIMINAZIONE / ABILITAZIONE`
**Internamente chiama**: `OBJ_Abilitazione.Elimina()`

Eliminazione fisica (DELETE diretto su ABILITAZIONI).

**Attenzione**: dopo l'eliminazione, ricaricare il contesto `CTX_APP_ABL`
tramite `OBJ_Profilo.CaricaContestoAbilitazioni()` se la sessione è già attiva.

---

## Operatori Supportati

| Operatore | Significato SQL | Esempio valore |
|-----------|-----------------|----------------|
| `=` | Uguaglianza / IN (più valori) | `S` oppure `S;N` |
| `<>` | Diverso da | `N` |
| `<` | Minore di | `100` |
| `<=` | Minore o uguale | `100` |
| `>` | Maggiore di | `0` |
| `>=` | Maggiore o uguale | `1` |
| `LIKE` | Pattern matching | `rossi%` |
| `BETWEEN` | Intervallo | `100;500` (due valori sep. da `;`) |
| `NULL` | IS NULL | (valore ignorato) |
| `NOTNULL` | IS NOT NULL | (valore ignorato) |

---

## Metodo RisolviSinonimo (per BuildWhere)

| Sinonimo | Colonna | Tipo |
|----------|---------|------|
| `ID_CHIAVE` | `ID_CHIAVE` | N (NUMBER) |
| `ID_PROFILO` | `ID_PROFILO` | N |
| `TIPO` | `TIPO` | N |
| `CHIAVE` | `CHIAVE` | V (VARCHAR) |
| `VALORE` | `VALORE` | V |
| `OPERATORE` | `OPERATORE` | V |

---

[← Privilegi](privilegi.md) | [← Torna all'indice](../../README.md)
