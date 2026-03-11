# SISTER — Panoramica dell'API

**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Scopo

La libreria SISTER espone operazioni di gestione utenti, sessioni e controllo accessi
tramite due modalità di integrazione:

1. **Chiamate PL/SQL interne** — accesso diretto ai TYPE Oracle e a `PKG_APP`
2. **REST via ORDS** — endpoint HTTP esposti da Oracle REST Data Services

In entrambi i casi l'output è sempre strutturato tramite `OBJ_Esito` (JSON),
mai markup di presentazione.

---

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| Database | Oracle Database 19c |
| Linguaggio | PL/SQL con Oracle Object Types (ereditarietà) |
| REST API | ORDS — Oracle REST Data Services |
| Sessione | Oracle Application Context (`DBMS_SESSION`, `SYS_CONTEXT`) |
| Sicurezza query | `DBMS_ASSERT.SIMPLE_SQL_NAME` |
| Stack trace | `UTL_CALL_STACK` |
| Hashing password | `STANDARD_HASH('password', 'MD5')` |

---

## Principi Architetturali

### Separazione logica / presentazione
La libreria non produce HTML o markup. Restituisce sempre dati strutturati in formato JSON.

### Output uniforme tramite OBJ_Esito
Ogni operazione restituisce (o popola) un oggetto `OBJ_Esito` con i campi:

```json
{
  "StatusCode": 200,
  "Messaggio": "Utente creato con successo",
  "Errori": null,
  "DebugInfo": null
}
```

### RBAC centralizzato
`PKG_APP.VerificaAccesso()` è il punto unico di controllo accessi. Ogni metodo CRUD
lo chiama come prima istruzione. L'accesso è consentito solo se:
- la sessione è attiva (CTX_APP_IDS popolato)
- l'azione è configurata in TBL_AZIONI
- esiste un privilegio attivo per la coppia (azione, ruolo)
- i controlli logici dell'oggetto restituiscono TRUE

### Nessun COMMIT incorporato
I metodi CRUD non eseguono COMMIT (eccetto `OBJ_Sessione.Crea`). La gestione
della transazione è responsabilità del chiamante.

### SQL Injection Prevention
`DBMS_ASSERT` valida tutti gli input usati in query dinamiche (`BuildWhere`).
I valori numerici sono validati con `TO_NUMBER`, le date con `TO_DATE`.

---

## Gerarchia dei Tipi

```
OBJ_Esito           (standalone — risposta HTTP; Log() usa primitive Oracle dirette)
OBJ_Profilatore     (base NOT FINAL — BuildWhere, utility, lettura contesti)
  ├── OBJ_Sessione  — autenticazione, ciclo di vita sessione
  ├── OBJ_Utente    — CRUD utente con soft delete
  ├── OBJ_Profilo   — CRUD profilo + caricamento contesto abilitazioni
  ├── OBJ_Ruolo     — lettura ruolo (solo Carica)
  ├── OBJ_Azione    — CRUD catalogo azioni RBAC
  ├── OBJ_Privilegio — CRUD associazioni ruolo-azione con soft delete
  └── OBJ_Abilitazione — CRUD filtri di visibilità per profilo
```

---

## Application Contexts

| Context | Tipo | Contenuto |
|---------|------|-----------|
| `CTX_APP_IDS` | Sessione | `ID_SESSIONE`, `ID_UTENTE`, `ID_PROFILO`, `ID_RUOLO` |
| `CTX_APP_PAR` | Sistema | `DEBUG_LEVEL`, `DEBUG_ENABLED`, `LOG_CONTATORE` |
| `CTX_APP_ABL` | Autorizzazione | Filtri di visibilità del profilo (caricati all'avvio) |
| `CTX_APP_FLT` | Ricerca | Filtri aggiuntivi impostati a runtime dal chiamante |
| `CTX_APP_LOG` | Log | Buffer messaggi JSON con chiave progressiva `LOG_0000001`, ... |

---

## Modello di Sicurezza

### Autenticazione
- Username e password (hash MD5) verificati nella tabella `UTENTI`
- Profilo selezionato dall'utente al momento del login
- Scadenza password controllata (`DATA_SCADENZA_PASSWORD >= SYSDATE`)
- Utente e profilo devono essere attivi (`ATTIVO = 'S'`)

### Autorizzazione (RBAC)
- Ogni utente ha uno o più **profili**, ognuno associato a un **ruolo**
- I **privilegi** definiscono quali **azioni** un ruolo può eseguire
- Le **abilitazioni** definiscono i filtri di visibilità (CTX_APP_ABL)

### Profilazione automatica delle query (BuildWhere)
- `OBJ_Profilatore.BuildWhere()` costruisce clausole WHERE dinamiche
  combinando CTX_APP_ABL (autorizzazioni) e CTX_APP_FLT (filtri ricerca)
- La traduzione da nomi logici a colonne fisiche è delegata a `RisolviSinonimo()`
  implementato in ogni sottotipo

---

## Flusso Tipo di una Chiamata CRUD

```
Client → PKG_APP.Inizializza(username, password, idProfilo)
              └── Popola CTX_APP_IDS, CTX_APP_ABL

Client → OBJ_Utente()               -- istanzia l'oggetto
       → utente.Login := 'nuovo'    -- popola i campi
       → utente.Crea()              -- esegue il CRUD
              └── PKG_APP.VerificaAccesso('INSERIMENTO', 'UTENTE', NULL, TRUE)
                      ├── [401] se sessione non attiva
                      ├── [401] se azione non configurata
                      ├── [401] se privilegio mancante
                      └── [200] → INSERT INTO UTENTI

Client → SELF.Esito.StatusCode      -- verifica il risultato
```

---

## Versioning

La libreria non implementa ancora versioning formale degli endpoint ORDS.
La versione attuale della libreria è indicata nel `CHANGELOG.md` in root.

[← Torna all'indice](../README.md)
