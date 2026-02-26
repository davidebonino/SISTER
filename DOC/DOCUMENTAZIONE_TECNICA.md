# SISTER - Documentazione Tecnica Completa

**Data**: 3 Febbraio 2026  
**Progetto**: SISTER - Sistema Informativo Sanitario per la Gestione Integrata dei Servizi Territoriali  
**Tecnologia**: Oracle Database con PL/SQL Object-Oriented

---

## Sommario

1. [Panoramica Architettura](#1-panoramica-architettura)
2. [Gerarchia Degli Oggetti](#2-gerarchia-degli-oggetti)
3. [Flusso di Autenticazione e Sessione](#3-flusso-di-autenticazione-e-sessione)
4. [Moduli Funzionali](#4-moduli-funzionali)
5. [Oggetti e Tipi](#5-oggetti-e-tipi)
6. [Package Principali](#6-package-principali)
7. [Funzioni Standalone](#7-funzioni-standalone)
8. [Procedure Stored](#8-procedure-stored)
9. [Pattern di Programmazione](#9-pattern-di-programmazione)
10. [Modello di Sicurezza](#10-modello-di-sicurezza)

---

## 1. Panoramica Architettura

### 1.1 Filosofia del Progetto

SISTER è un sistema healthcare basato su **Object-Oriented PL/SQL** che implementa un'architettura a tre livelli:

```
┌─────────────────────────────────────────┐
│  CLIENT LAYER (API REST / UI)           │
├─────────────────────────────────────────┤
│  APPLICATION LAYER (PKG_*)              │
│  - Business Logic                       │
│  - Privilege Checks                     │
│  - Session Management                   │
├─────────────────────────────────────────┤
│  DATA LAYER (OBJ_* Types + Tables)      │
│  - CRUD Operations                      │
│  - Domain Objects                       │
│  - Security Policies                    │
└─────────────────────────────────────────┘
```

### 1.2 Principi di Design

- **Domain-Driven Design**: Ogni dominio è rappresentato da un tipo custom (`OBJ_*`)
- **Stateful Profiling**: La sessione mantiene il contesto utente in variabili globali
- **Privilege-Based Security**: Ogni operazione verifica i diritti prima dell'esecuzione
- **Soft Deletes**: I record non vengono cancellati ma marcati con `Attivo = 'N'`
- **Audit Trail**: Ogni oggetto traccia `DataIns`, `UtenteIns`, `DataAgg`, `UtenteAgg`

### 1.3 Struttura Cartelle

```
SISTER/
├── OBJ/                    # Type definitions (11 tipi)
│   ├── OBJ_Profilatore.sql     # Base type
│   ├── OBJ_Esito.sql           # Error handling
│   ├── OBJ_Sessione.sql        # Authentication
│   ├── OBJ_Profilo.sql         # User profile
│   ├── OBJ_Utente.sql          # User details
│   ├── OBJ_Ruolo.sql           # Role definition
│   ├── OBJ_Privilegio.sql      # Permission mapping
│   ├── OBJ_Azione.sql          # Action definition
│   ├── OBJ_Abilitazione.sql    # Authorization
│   ├── OBJ_Condizioni.sql      # JSON-based filtering
│   └── OBJ_CONFIG.sql          # Configuration
├── PKG/                    # Package logic (8 pacchetti)
│   ├── PKG_APP.sql         # Session initialization
│   ├── PKG_PROXY.sql       # Session globals
│   ├── PKG_AAA.sql         # Auth/Auth/Accounting
│   ├── PKG_ANA.sql         # Anagrafe (Registry)
│   ├── PKG_DOM.sql         # Domiciliare (Home Care)
│   ├── PKG_RES.sql         # Residenziale (Residential)
│   ├── PKG_AURA.sql        # AURA Integration
│   ├── PKG_CORREZIONE_DATI.sql # Data Sanitation
│   ├── UTILITIES.sql       # Helper functions
│   └── TEST/               # Unit tests (8 test files)
├── FN/                     # Standalone functions (2)
│   ├── F_GENERA_CODICE_LATTEA.sql
│   └── F_GIORNI_PER_URGENZA.sql
├── SP/                     # Stored procedures (5)
│   ├── SP_AGGANCIA_RICHIESTA_ECMWED.sql
│   ├── SP_AGGIORNA_GRADUATORIA.sql
│   ├── SP_CALCOLA_STATO.sql
│   ├── SP_RICREA_QUOTE_PIC_RES.sql
│   └── [+1 altro]
└── PROC/                   # Deployment scripts (1)
    └── Ricrea oggetti.sql
```

---

## 2. Gerarchia Degli Oggetti

### 2.1 Albero di Eredità

```
OBJ_Profilatore (BASE TYPE)
    ├── Contiene: Esito (OBJ_Esito), Condizioni (OBJ_Condizioni)
    │             gIdProfilo, gIdRuolo, gIdSessione, gIdUtente
    │
    ├── OBJ_Sessione
    │   └── Gestisce: Autenticazione, Token di sessione
    │
    ├── OBJ_Profilo
    │   └── Gestisce: Profili utente, Ruoli, Abilitazioni
    │
    ├── OBJ_Utente
    │   └── Gestisce: Dati anagrafici, Scadenze password
    │
    ├── OBJ_Ruolo
    │   └── Gestisce: Definizione ruoli, Mappature azioni
    │
    ├── OBJ_Privilegio
    │   └── Gestisce: Verifica permessi (Azione + Ruolo)
    │
    ├── OBJ_Azione
    │   └── Gestisce: Tipi di azione (INSERIMENTO, MODIFICA, etc)
    │
    ├── OBJ_Abilitazione
    │   └── Gestisce: Abilitazioni specifiche per profilo
    │
    └── OBJ_Condizioni
        └── Gestisce: Filtri JSON per row-level security
```

### 2.2 Attributi Comuni

Tutti gli oggetti che estendono `OBJ_Profilatore` contengono:

| Attributo | Tipo | Descrizione |
|-----------|------|-------------|
| `Esito` | `OBJ_Esito` | Risultato dell'ultima operazione |
| `Condizioni` | `OBJ_Condizioni` | Filtri di sicurezza in JSON |
| `DataIns` | `DATE` | Data di inserimento |
| `UtenteIns` | `NUMBER` | ID utente che ha inserito |
| `DataAgg` | `DATE` | Data di ultimo aggiornamento |
| `UtenteAgg` | `NUMBER` | ID utente che ha aggiornato |
| `Attivo` | `VARCHAR2(1)` | Flag soft-delete ('S' = attivo, 'N' = cancellato) |

---

## 3. Flusso di Autenticazione e Sessione

### 3.1 Sequenza di Login

```
1. Client chiama: PKG_APP.Inizializza(pUsername, pKeyword, pIdProfilo)
   │
   ├─> OBJ_Sessione.Crea(pUsername, pKeyword, pIdProfilo)
   │   └─> Verifica credenziali nella tabella UTENTI
   │   └─> Valida: LOGIN = username, PASSWORD_0 = MD5(password)
   │   └─> Controlla: ATTIVO = 'S', DATA_SCADENZA_PASSWORD >= SYSDATE
   │   └─> Genera: SYS_GUID() → IdSessione (RAW(16))
   │   └─> Inserisce: TBL_SESSIONI (IdSessione, IdProfilo, IdRuolo, Stato, Data)
   │   └─> Ritorna: OBJ_Sessione con Esito = 201 (Created)
   │
   ├─> PKG_PROXY.gIdSessione := gSessione.IdSessione
   │
   ├─> OBJ_Profilo.Carica(gSessione.IdProfilo)
   │   └─> Carica il profilo della sessione
   │   └─> PKG_PROXY.gIdProfilo := gProfilo.IdProfilo
   │   └─> PKG_PROXY.gIdRuolo := gProfilo.IdRuolo
   │
   ├─> OBJ_Profilo.CaricaContestoAbilitazioni(gProfilo.IdProfilo)
   │   └─> Carica tutti i privilegi del profilo in CTX_APP_ABL
   │
   └─> OBJ_Utente.Carica(gProfilo.IdUtente)
       └─> PKG_PROXY.gIdUtente := gUtente.IdUtente
```

### 3.2 Struttura Sessione

**Tabella: TBL_SESSIONI**

| Colonna | Tipo | Descrizione |
|---------|------|-------------|
| `ID_SESSIONE` | `RAW(16)` | Primary Key (GUID) |
| `ID_PROFILO` | `NUMBER` | Foreign Key a PROFILI |
| `ID_RUOLO` | `NUMBER` | Foreign Key a RUOLI |
| `STATO` | `CHAR(1)` | 'A' = Attiva, 'C' = Chiusa |
| `DATA` | `DATE` | Timestamp creazione |

### 3.3 Variabili Globali di Sessione (PKG_PROXY)

```sql
gIdSessione VARCHAR2(32)  -- GUID della sessione corrente
gIdProfilo  NUMBER        -- ID profilo dell'utente
gIdRuolo    NUMBER        -- ID ruolo dell'utente
gIdUtente   NUMBER        -- ID utente
```

### 3.4 Contesti Applicativi

SISTER utilizza tre contesti Oracle per la gestione delle informazioni di sessione:

```sql
CREATE CONTEXT CTX_APP_IDS USING PKG_APP;   -- Identità (sessione, profilo, ruolo, utente)
CREATE CONTEXT CTX_APP_ABL USING PKG_APP;   -- Abilitazioni (privilegi dell'utente)
CREATE CONTEXT CTX_APP_FLT USING PKG_APP;   -- Filtri (condizioni di ricerca)
```

**Popolamento**:
```sql
PKG_APP.AggiungiContesto('CTX_APP_IDS', 'ID_PROFILO', vValue);
PKG_APP.AggiungiContesto('CTX_APP_ABL', 'CHIAVE', valore);
```

---

## 4. Moduli Funzionali

### 4.1 AAA - Autenticazione, Autorizzazione, Accounting

**File**: `PKG\PKG_AAA.sql` (1215 righe)

**Responsabilità**:
- Gestione dell'autenticazione (login)
- Verifica dei privilegi sulle azioni
- Logging degli accessi
- Profilazione delle query (row-level security)

**Procedure e Funzioni Principali**:

| Nome | Tipo | Descrizione |
|------|------|-------------|
| `CreaAbilitazione` | PROCEDURE | Crea nuova abilitazione |
| `CercaPrivilegio` | PROCEDURE | Cerca privilegio per azione e ruolo |
| `CercaAzione` | FUNCTION | Cerca azione per ID |
| `CercaAzione` | PROCEDURE | Cerca azione per parametri (tipo, oggetto, ambito) |
| `ControllaAccesso` | FUNCTION | Verifica se accesso autorizzato |
| `ProfilaTabella` | FUNCTION | Aggiunge WHERE clause di sicurezza |
| `CercaCampoInTabella` | FUNCTION | Valida colonna in tabella |
| `CreaAzione` | PROCEDURE | Crea nuova azione |
| `CreaAccesso` | PROCEDURE | Registra accesso utente |
| `CreaPrivilegio` | PROCEDURE | Crea nuovo privilegio |

**Tipi di Dati Definiti**:

```sql
TYPE tEsitoChiamata IS RECORD (  
    StatusCode   NUMBER        := 200,
    Messaggio    VARCHAR2(512) := 'Successo',
    NumeroErrori NUMBER        := 0,
    Errori       CLOB          := NULL,
    DebugInfo    CLOB          := NULL 
);

TYPE tCondizioneRicerca IS RECORD (
    Valore     VARCHAR2(256),
    TipoCampo  VARCHAR2(24),
    Condizione VARCHAR2(24)
);
```

**Tabelle Coinvolte**:
- `TBL_AZIONI` - Definizione azioni (INSERIMENTO, MODIFICA, ELIMINAZIONE, VISUALIZZAZIONE, RICERCA)
- `TBL_PRIVILEGI` - Mappature azione-ruolo
- `TBL_ACCESSI` - Log degli accessi
- `TBL_VERSIONI` - Versionamento codice
- `UTENTI` - Credenziali utente
- `PROFILI` - Profili utente

---

### 4.2 ANA - Anagrafe (Anagrafi Pazienti)

**File**: `PKG\PKG_ANA.sql` (82 righe)

**Responsabilità**:
- Ricerca di assistiti (pazienti)
- Visualizzazione dati anagrafici

**Procedure e Funzioni Principali**:

| Nome | Tipo | Descrizione |
|------|------|-------------|
| `CercaAssistito` | PROCEDURE | Ricerca assistito per ID con profilazione |

**Logica**:
1. Verifica autorizzazione tramite `PKG_AAA.ControllaAccesso()`
2. Costruisce SQL per query anagrafe
3. Applica filtri di sicurezza tramite `PKG_AAA.ProfilaTabella()`
4. Ritorna `SYS_REFCURSOR` con risultati

**Tabelle**:
- `ANAGRAFE` - Dati anagrafici assistiti
- `ASSISTITI` - Dettagli assistiti

---

### 4.3 DOM - Domiciliare (Assistenza Domiciliare)

**File**: `PKG\PKG_DOM.sql` (130 righe)

**Responsabilità**:
- Gestione prese in carico domiciliari
- Pianificazione interventi
- Tracciamento visite

**Procedure e Funzioni Principali**:

| Nome | Tipo | Descrizione |
|------|------|-------------|
| `CercaPresaCarico` | PROCEDURE | Ricerca presa in carico domiciliare |
| `CercaPreseCarico` | PROCEDURE | Ricerca liste di prese in carico |

**Tabelle**:
- `PRESE_IN_CARICO` - Prese in carico domiciliari
- `INTERVENTI` - Interventi domiciliari

---

### 4.4 RES - Residenziale (Strutture Residenziali)

**File**: `PKG\PKG_RES.sql`

**Responsabilità**:
- Gestione strutture residenziali
- Gestione posti letto
- Pianificazione ricoveri

---

### 4.5 AURA - Integrazione Sistema Esterno

**File**: `PKG\PKG_AURA.sql`

**Responsabilità**:
- Sincronizzazione dati XML con sistema AURA
- Import/export dati sanitari
- Gestione tracciati HL7/XML

---

### 4.6 CORREZIONE_DATI - Data Sanitation

**File**: `PKG\PKG_CORREZIONE_DATI.sql`

**Responsabilità**:
- Batch sanitization di dati
- Correzione errori storici
- Integrità referenziale

---

### 4.7 APP - Gestione Applicativa

**File**: `PKG\PKG_APP.sql` (116 righe)

**Responsabilità**:
- Inizializzazione sessione
- Gestione contesti applicativi
- Caricamento dati di sessione

**Procedure e Funzioni Principali**:

| Nome | Tipo | Descrizione |
|------|------|-------------|
| `Inizializza` | FUNCTION | Inizializza sessione utente |
| `CreaContesto` | PROCEDURE | Crea contesto Oracle |
| `AggiungiContesto` | PROCEDURE | Aggiunge coppia chiave-valore a contesto |
| `RimuoviContesto` | PROCEDURE | Rimuove elemento da contesto |
| `PulisciContesto` | PROCEDURE | Svuota un contesto |
| `VisualizzaContesto` | FUNCTION | Visualizza contenuto contesto |

**Variabili Globali**:

```sql
gSessione  OBJ_Sessione;  -- Sessione corrente
gProfilo   OBJ_Profilo;   -- Profilo utente
gUtente    OBJ_Utente;    -- Dettagli utente
```

---

### 4.8 PROXY - Variabili Globali di Sessione

**File**: `PKG\PKG_PROXY.sql` (15 righe)

**Responsabilità**:
- Mantenimento variabili globali di sessione
- Accesso veloce alle informazioni di contesto

**Variabili Globali**:

```sql
gIdSessione VARCHAR2(32) := NULL;
gIdProfilo  NUMBER       := NULL;
gIdRuolo    NUMBER       := NULL;
gIdUtente   NUMBER       := NULL;
```

---

## 5. Oggetti e Tipi

### 5.1 OBJ_Profilatore (BASE TYPE)

**File**: `OBJ\OBJ_Profilatore.sql` (295 righe)

**Scopo**: Tipo base per tutti gli oggetti di dominio con funzionalità di profilazione.

**Attributi**:
```sql
Esito           OBJ_Esito       -- Risultato operazione
Condizioni      OBJ_Condizioni  -- Filtri di sicurezza
```

**Metodi Statici**:

| Metodo | Ritorno | Descrizione |
|--------|---------|-------------|
| `MioIdProfilo()` | `NUMBER` | Restituisce ID profilo sessione (da PKG_PROXY) |
| `MioIdRuolo()` | `NUMBER` | Restituisce ID ruolo sessione |
| `MioIdSessione()` | `VARCHAR2` | Restituisce ID sessione |
| `MioIdUtente()` | `NUMBER` | Restituisce ID utente |

**Metodi di Utilità**:

| Metodo | Descrizione |
|--------|-------------|
| `OperatoreValido()` | Lista operatori SQL consentiti (=, <>, <, <=, >, >=, LIKE, IN, NOT IN, BETWEEN, IS NULL, IS NOT NULL) |
| `TipoDatoValido()` | Lista tipi dati consentiti (NUMBER, VARCHAR2, DATE) |
| `InLista()` | Verifica se valore è in lista |
| `Esc()` | Escape apici in stringhe |
| `ConvertiDato()` | Converte valore a tipo SQL specifico |
| `build_where()` | Costruisce WHERE clause da OBJ_Condizioni |

**Utilizzo Tipico**:

```sql
DECLARE
  vProfilo OBJ_Profilo;
BEGIN
  IF OBJ_Profilo.MioIdRuolo() IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE('Ruolo: ' || OBJ_Profilo.MioIdRuolo());
  END IF;
END;
```

---

### 5.2 OBJ_Esito

**File**: `OBJ\OBJ_Esito.sql` (52 righe)

**Scopo**: Standardizzazione degli esiti di operazioni (pattern HTTP status codes).

**Attributi**:
```sql
StatusCode   NUMBER       -- 200, 201, 400, 401, 403, 404, 409, 500...
Messaggio    VARCHAR2(512) -- Messaggio leggibile
Errori       CLOB         -- Lista errori strutturata [{errore: ...}]
DebugInfo    CLOB         -- Info di debug (non sensibili)
```

**Metodi**:

| Metodo | Descrizione |
|--------|-------------|
| `Imposta(StatusCode, Messaggio, Errore, DebugInfo)` | Crea OBJ_Esito con parametri |
| `Info()` | Ritorna stringa 'ESITO' |

**Status Code Comuni**:

| Codice | Significato |
|--------|-------------|
| `200` | Operazione riuscita |
| `201` | Risorsa creata |
| `204` | Nessun contenuto |
| `400` | Richiesta malformata / errore logico |
| `401` | Non autenticato / privilegi insufficienti |
| `403` | Accesso vietato |
| `404` | Risorsa non trovata |
| `409` | Conflitto (es. PK duplicata) |
| `500` | Errore interno del server |

**Utilizzo**:

```sql
SELF.Esito := OBJ_Esito.Imposta(200, 'Resource created', NULL, NULL);
SELF.Esito := OBJ_Esito.Imposta(401, 'Auth failed', 'IdRuolo: ' || MioIdRuolo(), NULL);
```

---

### 5.3 OBJ_Sessione

**File**: `OBJ\OBJ_Sessione.sql` (129 righe)

**Scopo**: Gestione autenticazione e creazione sessioni.

**Attributi**:
```sql
IdSessione RAW(16)  -- GUID generato con SYS_GUID()
IdProfilo  NUMBER   -- Profilo dell'utente
IdRuolo    NUMBER   -- Ruolo dell'utente
Stato      CHAR(1)  -- 'A' = Attiva, 'C' = Chiusa
Data       DATE     -- Timestamp creazione sessione
```

**Metodi**:

| Metodo | Descrizione |
|--------|-------------|
| `Crea(pUsername, pKeyword, pIdProfilo)` | Autentica utente e crea sessione |
| `Carica(pIdSessione)` | Carica sessione esistente |

**Processo di Autenticazione** (`Crea`):

1. Verifica credenziali in tabella UTENTI:
   - `LOGIN` = pUsername (case-insensitive)
   - `PASSWORD_0` = STANDARD_HASH(pKeyword, 'MD5')
   - `ATTIVO` = 'S'
   - `DATA_SCADENZA_PASSWORD` >= SYSDATE

2. Se validazione OK:
   - Genera `IdSessione` = `SYS_GUID()`
   - Inserisce record in `TBL_SESSIONI`
   - Ritorna `OBJ_Sessione` con `Esito.StatusCode = 201`

3. Se validazione FAIL:
   - Ritorna `OBJ_Sessione` con `Esito.StatusCode = 401`

---

### 5.4 OBJ_Profilo

**File**: `OBJ\OBJ_Profilo.sql` (308 righe)

**Scopo**: Rappresentazione profilo utente con CRUD operations.

**Attributi**:
```sql
IdProfilo     NUMBER        -- PK
IdUtente      NUMBER        -- FK a UTENTI
IdRuolo       NUMBER        -- FK a RUOLI
Nome          VARCHAR2(80)  -- Nome profilo
DataIns       DATE          -- Data inserimento
UtenteIns     NUMBER        -- Utente che ha inserito
DataAgg       DATE          -- Data aggiornamento
UtenteAgg     NUMBER        -- Utente che ha aggiornato
Attivo        VARCHAR2(1)   -- 'S' = attivo, 'N' = eliminato (soft delete)
```

**Metodi**:

| Metodo | Descrizione |
|--------|-------------|
| `Carica(pIdProfilo)` | Carica profilo dal DB |
| `CaricaContestoAbilitazioni(pIdProfilo)` | Popola CTX_APP_ABL con privilegi |
| `ControlliLogici()` | Valida coerenza dati (es. FK) |
| `Crea()` | Inserisce nuovo profilo (con privilege check) |
| `Modifica()` | Aggiorna profilo (con privilege check) |
| `Elimina()` | Soft-delete profilo (con privilege check) |

**Logica Privilege Check** (es. in `Crea`):

```sql
IF OBJ_Profilo.MioIdRuolo() IS NOT NULL THEN
  vIdPrivilegio := OBJ_Privilegio.Cerca(
    OBJ_Azione.Cerca('INSERIMENTO', 'PROFILO', NULL), 
    OBJ_Profilo.MioIdRuolo()
  );
  IF vIdPrivilegio IS NOT NULL THEN
    -- Procedi con INSERT
  ELSE
    SELF.Esito := OBJ_Esito.Imposta(401, 'privilegi insufficienti', ...);
  END IF;
END IF;
```

---

### 5.5 OBJ_Utente

**File**: `OBJ\OBJ_Utente.sql`

**Scopo**: Dati dettagliati dell'utente (anagrafici, credenziali, scadenze).

**Attributi**:
```sql
IdUtente              NUMBER
Nome                  VARCHAR2(80)
Cognome               VARCHAR2(80)
Email                 VARCHAR2(256)
Login                 VARCHAR2(80)
Password_0            VARCHAR2(64)    -- MD5 hash
Password_0_Scadenza   DATE
Attivo                VARCHAR2(1)
DataIns, UtenteIns, DataAgg, UtenteAgg
```

**Metodi**: `Carica()`, `Crea()`, `Modifica()`, `Elimina()`

---

### 5.6 OBJ_Ruolo

**File**: `OBJ\OBJ_Ruolo.sql`

**Scopo**: Definizione ruoli nel sistema (es. MEDICO, INFERMIERE, AMMINISTRATORE).

**Attributi**:
```sql
IdRuolo       NUMBER
Descrizione   VARCHAR2(256)
Attivo        VARCHAR2(1)
```

**Metodi**: `Carica()`, `Crea()`, `Modifica()`, `Elimina()`

---

### 5.7 OBJ_Privilegio

**File**: `OBJ\OBJ_Privilegio.sql` (322 righe)

**Scopo**: Mappatura azione-ruolo per implementare permission model.

**Attributi**:
```sql
IdPrivilegio  NUMBER      -- PK
IdAzione      NUMBER      -- FK a AZIONI
IdRuolo       NUMBER      -- FK a RUOLI
DataIns, UtenteIns, DataAgg, UtenteAgg
Attivo        VARCHAR2(1)
```

**Metodi**:

| Metodo | Descrizione |
|--------|-------------|
| `Carica(pIdPrivilegio)` | Carica per PK |
| `Carica(pIdAzione, pIdRuolo)` | Carica per azione e ruolo |
| `Cerca(pIdAzione, pIdRuolo)` | Ricerca e ritorna ID (NULL se non trovato) |

**Flusso di Verifica Privilegi**:

```
OBJ_Azione.Cerca('INSERIMENTO', 'PROFILO', NULL)
    ↓
Ritorna: IdAzione (es. 42)
    ↓
OBJ_Privilegio.Cerca(42, MioIdRuolo())
    ↓
Ritorna: IdPrivilegio se autorizzato, NULL se no
    ↓
IF vIdPrivilegio IS NOT NULL THEN
    -- Procedi con operazione
ELSE
    -- Nega operazione (401 - Unauthorized)
```

---

### 5.8 OBJ_Azione

**File**: `OBJ\OBJ_Azione.sql`

**Scopo**: Definizione azioni permesse nel sistema.

**Attributi**:
```sql
IdAzione   NUMBER
Tipo       VARCHAR2(24)    -- INSERIMENTO, MODIFICA, ELIMINAZIONE, 
                            -- VISUALIZZAZIONE, RICERCA
Oggetto    VARCHAR2(80)    -- PROFILO, UTENTE, RUOLO, PRIVILEGIO, 
                            -- ABILITAZIONE, AZIONE, ASSISTITO, 
                            -- PRESA_IN_CARICO, ...
Ambito     VARCHAR2(80)    -- NULL o specifico (es. 'DOMICILIARE')
Attivo     VARCHAR2(1)
```

**Metodi**:

| Metodo | Descrizione |
|--------|-------------|
| `Cerca(pTipo, pOggetto, pAmbito)` | Trova IdAzione per query |
| `Carica(pIdAzione)` | Carica per PK |

**Tipi Azione**:
- `INSERIMENTO` - Creazione nuovo record
- `MODIFICA` - Aggiornamento record
- `ELIMINAZIONE` - Cancellazione (soft delete)
- `VISUALIZZAZIONE` - Lettura dati
- `RICERCA` - Ricerca/filtering

---

### 5.9 OBJ_Abilitazione

**File**: `OBJ\OBJ_Abilitazione.sql`

**Scopo**: Abilitazioni specifiche per profilo (es. restrizioni geografiche).

**Attributi**:
```sql
IdAbilitazione NUMBER
IdProfilo      NUMBER
Chiave         VARCHAR2(256)  -- Nome della restrizione
Valore         VARCHAR2(256)  -- Valore della restrizione
Operatore      VARCHAR2(24)   -- Operatore di confronto
```

**Utilizzo**: Filtraggio row-level security
```sql
-- Es. profilo visibile solo nella provincia di Torino
Chiave: 'PROVINCIA'
Valore: 'TO'
Operatore: '='
```

---

### 5.10 OBJ_Condizioni

**File**: `OBJ\OBJ_Condizioni.sql` (71 righe)

**Scopo**: Filtri di ricerca in formato JSON per implementare row-level security.

**Attributi**:
```sql
Condizioni  CLOB  -- JSON object con filtri
```

**Struttura JSON**:

```json
{
  "PROVINCIA": {
    "TIPO": "VARCHAR2",
    "CONDIZIONE": "=",
    "VALORE": "TO"
  },
  "DISTRETTO": {
    "TIPO": "NUMBER",
    "CONDIZIONE": "IN",
    "VALORE": "10,20,30"
  }
}
```

**Metodi**:

| Metodo | Descrizione |
|--------|-------------|
| `Aggiungi(NomeCampo, Tipo, Condizione, Valore)` | Aggiunge filtro |
| `Mostra()` | Ritorna JSON completo |

---

### 5.11 OBJ_CONFIG

**File**: `OBJ\OBJ_CONFIG.sql`

**Scopo**: Configurazione applicativa (parametri di sistema).

---

## 6. Package Principali

Vedi Sezione 4 (Moduli Funzionali) per dettagli su PKG_AAA, PKG_ANA, PKG_DOM, PKG_RES, PKG_APP, PKG_PROXY, PKG_AURA, PKG_CORREZIONE_DATI.

### 6.1 Matrice Dipendenze

```
PKG_APP
  ├── OBJ_Sessione (autenticazione)
  ├── OBJ_Profilo (caricamento profilo)
  └── OBJ_Utente (caricamento utente)

PKG_PROXY
  └── (nessuna dipendenza - solo variabili globali)

PKG_AAA
  ├── OBJ_Privilegio (controllo privilegi)
  ├── OBJ_Azione (lookup azione)
  └── OBJ_Profilatore (metodi utilità)

PKG_ANA, PKG_DOM, PKG_RES
  └── PKG_AAA (ControllaAccesso, ProfilaTabella)

PKG_AURA
  └── (interfaccia con sistema esterno)

PKG_CORREZIONE_DATI
  └── (batch processing)
```

---

## 7. Funzioni Standalone

### 7.1 F_GENERA_CODICE_LATTEA

**File**: `FN\F_GENERA_CODICE_LATTEA.sql` (90 righe)

**Firma**:
```sql
FUNCTION F_GENERA_CODICE_LATTEA(PAR_ID_DISTRETTO NUMBER) RETURN NUMBER
```

**Scopo**: Genera codici progressivi per documenti LATTEA (Cartelle Cliniche).

**Logica**:

1. Riceve ID distretto
2. Verifica accorpamenti distretti (tabella `ACCORPAMENTO_DISTRETTI`)
3. Ricerca progressivo in `PROGRESSIVI_LATTEA` per distretto accorpato
4. Incrementa progressivo e lo ritorna
5. Se non esiste, inserisce nuovo record con progressivo = 1

**Utilizzo**: Generazione identificativi univoci per tracciati clinici

**Tabelle**:
- `PROGRESSIVI_LATTEA` - Contatori progressivi per distretto
- `ACCORPAMENTO_DISTRETTI` - Mapping distretti accorpati

**Gestione Concorrenza**: Usa `FOR UPDATE` per bloccare riga durante lettura/incremento

---

### 7.2 F_GIORNI_PER_URGENZA

**File**: `FN\F_GIORNI_PER_URGENZA.sql` (221 righe)

**Firma**:
```sql
FUNCTION F_GIORNI_PER_URGENZA (
    PAR_ID_ASSISTITO    IN NUMBER,
    PAR_ID_VALUTAZIONE  IN NUMBER,
    PAR_ID_DISTRETTO    IN NUMBER,
    PAR_DATA_RIF        IN DATE
) RETURN NUMBER
```

**Scopo**: Calcola numero di giorni per rispetto tempo risposta in base a urgenza della valutazione.

**Logica**:

1. Carica valutazione e relativa urgenza
2. Valuta case urgenza:
   - Urgenza 0-1: 0 giorni
   - Urgenza 2: Logica complessa con ciclo sui record correlati
3. Verifica se è presente progetto definitivo
4. Cerca data presa in carico residenziale
5. Confronta con data di riferimento
6. Calcola giorni trascorsi

**Valori Ritorno**: Numero di giorni (NULL se errore)

**Tabelle**:
- `VALUTAZIONI_UVG` - Valutazioni sanitarie
- `RICHIESTE` - Richieste di valutazione
- `LISTA_ATTESA_RESIDENZIALE` - Liste attesa strutture
- `PRESE_IN_CARICO` - Prese in carico residenziali
- `RINUNCE` - Rinunce assistiti

---

## 8. Procedure Stored

### 8.1 SP_CALCOLA_STATO

**File**: `SP\SP_CALCOLA_STATO.sql`

**Scopo**: Calcolo stato assistito (da dati clinici).

---

### 8.2 SP_AGGANCIA_RICHIESTA_ECMWED

**File**: `SP\SP_AGGANCIA_RICHIESTA_ECMWED.sql`

**Scopo**: Collegamento richiesta clinica con sistema ECMWED esterno.

---

### 8.3 SP_AGGIORNA_GRADUATORIA

**File**: `SP\SP_AGGIORNA_GRADUATORIA.sql`

**Scopo**: Aggiornamento posizioni in liste di attesa.

---

### 8.4 SP_RICREA_QUOTE_PIC_RES

**File**: `SP\SP_RICREA_QUOTE_PIC_RES.sql`

**Scopo**: Ricreazione quote per prese in carico residenziali.

---

## 9. Pattern di Programmazione

### 9.1 Pattern CRUD Completo

**Esempio: OBJ_Profilo.Crea()**

```sql
MEMBER PROCEDURE Crea IS
  vIdPrivilegio VARCHAR2(32);
BEGIN
  -- 1. VERIFICA SESSIONE
  IF OBJ_Profilo.MioIdRuolo() IS NOT NULL THEN
    
    -- 2. VERIFICA PRIVILEGIO
    vIdPrivilegio := OBJ_Privilegio.Cerca(
      OBJ_Azione.Cerca('INSERIMENTO', 'PROFILO', NULL), 
      OBJ_Profilo.MioIdRuolo()
    );
    
    IF vIdPrivilegio IS NOT NULL THEN
      
      -- 3. VALIDAZIONE LOGICA
      IF SELF.ControlliLogici() = FALSE THEN
        SELF.Esito := OBJ_Esito.Imposta(400, 'Errori controlli logici', ...);
        RETURN;
      END IF;
      
      -- 4. AUDIT FIELDS
      SELF.IdProfilo  := PROFILI_ID_PROFILO.NEXTVAL;
      SELF.Attivo     := 'S';
      SELF.DataIns    := SYSDATE;
      SELF.UtenteIns  := OBJ_Profilo.MioIdUtente();
      SELF.DataAgg    := SYSDATE;
      SELF.UtenteAgg  := OBJ_Profilo.MioIdUtente();
      
      -- 5. INSERT
      INSERT INTO PROFILI (...)
      VALUES (SELF.IdProfilo, SELF.IdUtente, ...);
      
      COMMIT;
      
      -- 6. ESITO SUCCESSO
      SELF.Esito := OBJ_Esito.Imposta(201, 'Profilo creato', NULL, NULL);
      
    ELSE
      SELF.Esito := OBJ_Esito.Imposta(401, 'privilegi insufficienti', ...);
    END IF;
    
  ELSE
    SELF.Esito := OBJ_Esito.Imposta(401, 'Non autenticato', ...);
  END IF;
END Crea;
```

### 9.2 Pattern Ricerca con Profilazione

**Esempio: PKG_ANA.CercaAssistito()**

```sql
PROCEDURE CercaAssistito (
  vIdAccesso   IN VARCHAR2,
  vIdAssistito IN NUMBER, 
  vRecordset   OUT SYS_REFCURSOR, 
  vErrore      OUT VARCHAR2  
) AS
  V_SQL VARCHAR2(4096);
BEGIN
  -- 1. VERIFICA ACCESSO E PRIVILEGIO
  IF PKG_AAA.ControllaAccesso(
     vIdAccesso, 'VISUALIZZAZIONE', 'ASSISTITO', 'ANAGRAFE'
  ) IS NOT NULL THEN
    
    -- 2. COSTRUISCI QUERY BASE
    V_SQL := 'SELECT * FROM ANAGRAFE ASS WHERE ASS.ID_ASSISTITO = ' 
             || vIdAssistito;
    
    -- 3. APPLICA PROFILAZIONE (ROW-LEVEL SECURITY)
    V_SQL := V_SQL || PKG_AAA.ProfilaTabella(
      vIdAccesso, 'ANAGRAFE', 'ASS'
    );
    
    -- 4. VALIDA PARAMETRI
    IF vIdAssistito IS NOT NULL THEN
      OPEN vRecordset FOR V_SQL;
    ELSE
      vErrore := 'IdAssistito non impostato';
    END IF;
    
  ELSE
    vErrore := 'Accesso non autorizzato o Privilegio mancante';
  END IF;
END CercaAssistito;
```

### 9.3 Pattern Autenticazione

**Esempio: OBJ_Sessione.Crea()**

```sql
STATIC FUNCTION Crea(
  pUsername   IN VARCHAR2, 
  pKeyword    IN VARCHAR2, 
  pIdProfilo  IN NUMBER
) RETURN OBJ_Sessione IS
  vIdRuolo NUMBER;
  vSessione OBJ_Sessione;
BEGIN
  vSessione := OBJ_Sessione();
  
  -- QUERY VERIFICA CREDENZIALI
  SELECT ID_RUOLO INTO vIdRuolo
  FROM UTENTI U, PROFILI P
  WHERE U.ID_UTENTE = P.ID_UTENTE
    AND U.ATTIVO = 'S'
    AND P.ATTIVO = 'S'
    AND UPPER(U.LOGIN) = UPPER(pUsername)
    AND UPPER(U.PASSWORD_0) = STANDARD_HASH(pKeyword, 'MD5')
    AND P.ID_PROFILO = TO_NUMBER(pIdProfilo)
    AND U.DATA_SCADENZA_PASSWORD >= SYSDATE
    AND ROWNUM = 1;
  
  IF vIdRuolo > 0 THEN
    -- AUTENTICAZIONE RIUSCITA
    vSessione.IdSessione := SYS_GUID();
    vSessione.IdProfilo := pIdProfilo;
    vSessione.IdRuolo := vIdRuolo;
    vSessione.Stato := 'A';
    vSessione.Data := SYSDATE;
    
    -- SALVA SESSIONE
    INSERT INTO TBL_SESSIONI 
    VALUES (vSessione.IdSessione, vSessione.IdProfilo, 
            vSessione.IdRuolo, vSessione.Stato, vSessione.Data);
    COMMIT;
    
    vSessione.Esito := OBJ_Esito.Imposta(201, 'Sessione creata', NULL, NULL);
    PKG_APP.gSessione := vSessione;
    RETURN vSessione;
  END IF;
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- AUTENTICAZIONE FALLITA
    vSessione.Esito := OBJ_Esito.Imposta(401, 'Auth fallita', ...);
    RETURN vSessione;
END Crea;
```

---

## 10. Modello di Sicurezza

### 10.1 Architettura AAA (Authentication, Authorization, Accounting)

```
┌─────────────────────────────────────────────────┐
│ AUTHENTICATION (Chi sei?)                       │
├─────────────────────────────────────────────────┤
│ OBJ_Sessione.Crea()                             │
│ - Verifica LOGIN + PASSWORD_0 (MD5)             │
│ - Valida ATTIVO = 'S'                           │
│ - Valida DATA_SCADENZA_PASSWORD                 │
│ - Genera SYS_GUID() → IdSessione                │
│ - Popola gIdUtente, gIdProfilo, gIdRuolo        │
└─────────────────────────────────────────────────┘
             ↓
┌─────────────────────────────────────────────────┐
│ AUTHORIZATION (Cosa puoi fare?)                 │
├─────────────────────────────────────────────────┤
│ OBJ_Privilegio.Cerca(IdAzione, IdRuolo)         │
│ - Verifica se (Azione, Ruolo) è mappata         │
│ - Se mappata: consenti operazione               │
│ - Se non mappata: nega operazione (401)         │
│                                                 │
│ OBJ_Abilitazione + OBJ_Condizioni               │
│ - Filtri row-level (es. provincia)              │
│ - Riduce visibilità dati per utente             │
└─────────────────────────────────────────────────┘
             ↓
┌─────────────────────────────────────────────────┐
│ ACCOUNTING (Cosa hai fatto?)                    │
├─────────────────────────────────────────────────┤
│ PKG_AAA.CreaAccesso()                           │
│ - Log di ogni accesso                           │
│ - Log in TBL_ACCESSI (ID_ACCESSO, IdUtente,    │
│   AZIONE, OGGETTO, DATA_ACCESSO, etc)          │
│ - Tracciamento attività per audit               │
└─────────────────────────────────────────────────┘
```

### 10.2 Privilege Lookup

**Tabelle Coinvolte**:

```
┌─────────┐         ┌──────────┐         ┌────────────┐
│ UTENTI  │         │ PROFILI  │         │ RUOLI      │
├─────────┤         ├──────────┤         ├────────────┤
│ID_UTENTE│────┐    │ID_PROFILO│────┐    │ID_RUOLO    │
│ LOGIN   │    └──→ │ID_UTENTE │    └──→ │ NOME       │
│PASSWORD │        │ID_RUOLO  │         │ DESCRIZIONE│
│ ATTIVO  │        │ NOME     │         │ ATTIVO     │
└─────────┘        │ ATTIVO   │         └────────────┘
                   └──────────┘                ↑
                                              │
                            ┌─────────────────┘
                            │
                   ┌─────────▼──────┐
                   │ TBL_PRIVILEGI  │
                   ├────────────────┤
                   │ID_PRIVILEGIO   │
                   │ ID_AZIONE      │
                   │ ID_RUOLO       │
                   │ ATTIVO         │
                   └────────┬───────┘
                            │
                   ┌────────▼──────┐
                   │ TBL_AZIONI     │
                   ├────────────────┤
                   │ ID_AZIONE      │
                   │ TIPO           │ (INSERIMENTO, etc)
                   │ OGGETTO        │ (PROFILO, etc)
                   │ AMBITO         │ (DOMICILIARE, etc)
                   │ ATTIVO         │
                   └────────────────┘
```

**Flusso Privilege Check**:

```
Utente richiede: INSERIMENTO di PROFILO

1. OBJ_Azione.Cerca('INSERIMENTO', 'PROFILO', NULL)
   → Query: SELECT ID_AZIONE FROM TBL_AZIONI
     WHERE TIPO = 'INSERIMENTO'
       AND OGGETTO = 'PROFILO'
       AND ATTIVO = 'S'
   → Ritorna: IdAzione = 42

2. OBJ_Privilegio.Cerca(42, MioIdRuolo())
   → Query: SELECT ID_PRIVILEGIO FROM TBL_PRIVILEGI
     WHERE ID_AZIONE = 42
       AND ID_RUOLO = 3 (es. ruolo dell'utente)
       AND ATTIVO = 'S'
   → Se trovato: Ritorna IdPrivilegio → CONSENTI
   → Se non trovato: Ritorna NULL → NEGA (401)
```

### 10.3 Row-Level Security (RLS)

**Implementazione tramite OBJ_Condizioni**:

```sql
DECLARE
  vCondizioni OBJ_Condizioni;
BEGIN
  vCondizioni := OBJ_Condizioni();
  
  -- Aggiunge filtro: solo assistiti provincia TO
  vCondizioni.Aggiungi('PROVINCIA', 'VARCHAR2', '=', 'TO');
  
  -- Aggiunge filtro: distretto IN (10, 20, 30)
  vCondizioni.Aggiungi('DISTRETTO', 'NUMBER', 'IN', '10,20,30');
  
  -- Risultato JSON:
  -- {
  --   "PROVINCIA": {
  --     "TIPO": "VARCHAR2",
  --     "CONDIZIONE": "=",
  --     "VALORE": "TO"
  --   },
  --   "DISTRETTO": {
  --     "TIPO": "NUMBER",
  --     "CONDIZIONE": "IN",
  --     "VALORE": "10,20,30"
  --   }
  -- }
END;
```

**Conversione a WHERE Clause**:

```sql
-- OBJ_Profilatore.build_where() converte OBJ_Condizioni in:
WHERE A.PROVINCIA = 'TO'
  AND A.DISTRETTO IN (10, 20, 30)
```

### 10.4 Soft Deletes

**Pattern**: Non cancellare fisicamente, marcare come inattivo

```sql
-- Eliminazione logica
PROCEDURE Elimina IS
BEGIN
  UPDATE PROFILI
  SET ATTIVO = 'N',
      DATAAGG = SYSDATE,
      UTENTEAGG = OBJ_Profilo.MioIdUtente()
  WHERE ID_PROFILO = SELF.IdProfilo;
END Elimina;

-- Lettura (esclude soft-deleted)
PROCEDURE CercaAttivi(...) IS
BEGIN
  SELECT * FROM PROFILI
  WHERE ATTIVO = 'S'
    AND ...
END;
```

### 10.5 Audit Trail

**Ogni oggetto traccia**:
- `DataIns` - Data creazione
- `UtenteIns` - Chi ha creato
- `DataAgg` - Data ultimo aggiornamento
- `UtenteAgg` - Chi ha aggiornato

**Log accessi** (TBL_ACCESSI):
- `ID_ACCESSO` - PK
- `ID_UTENTE` - Chi ha fatto
- `AZIONE` - VISUALIZZAZIONE, INSERIMENTO, etc
- `OGGETTO` - Su quale oggetto
- `DATA_ACCESSO` - Quando
- `RISULTATO` - Successo/Errore

---

## 11. Testing

### 11.1 Test Files

| File | Scopo |
|------|--------|
| `PKG/TEST/TEST_OBJ.sql` | Test caricamento oggetti |
| `PKG/TEST/TEST_AAA.sql` | Test autenticazione |
| `PKG/TEST/TEST_APP.sql` | Test inizializzazione app |
| `PKG/TEST/TEST_DOM.sql` | Test modulo domiciliare |
| `PKG/TEST/TEST_ANA.sql` | Test anagrafe |
| `PKG/TEST/UNIT_TEST_AAA.sql` | Unit test AAA |
| `PKG/TEST/test-requests.http` | REST API tests |

### 11.2 Esecuzione Test

```sql
-- Test singolo
@/path/to/PKG/TEST/TEST_OBJ.sql

-- In test-requests.http (REST client)
@rest POST http://localhost:8080/api/profili
```

---

## 12. Deployment

### 12.1 Script di Ricreazione

**File**: `PROC/Ricrea oggetti.sql`

Questo script ricrea (drop + recreate) tutti gli oggetti nel database:
1. Drop esistenti (se presenti)
2. Crea tipi (OBJ_*)
3. Crea package specs
4. Crea package bodies
5. Popola dati di setup

### 12.2 Sequenza Deployment

```
1. OBJ_Esito.sql
2. OBJ_Condizioni.sql
3. OBJ_Profilatore.sql
4. OBJ_Sessione.sql
5. OBJ_Profilo.sql
6. OBJ_Utente.sql
7. OBJ_Ruolo.sql
8. OBJ_Azione.sql
9. OBJ_Privilegio.sql
10. OBJ_Abilitazione.sql
11. OBJ_CONFIG.sql
12. PKG_PROXY.sql
13. PKG_APP.sql
14. PKG_AAA.sql
15. PKG_ANA.sql
16. PKG_DOM.sql
17. PKG_RES.sql
18. PKG_AURA.sql
19. PKG_CORREZIONE_DATI.sql
20. Funzioni FN/*.sql
21. Procedure SP/*.sql
```

---

## 13. Configurazione Contesti

### 13.1 Creazione Contesti (eseguire una sola volta)

```sql
CREATE CONTEXT CTX_APP_IDS USING PKG_APP;
CREATE CONTEXT CTX_APP_ABL USING PKG_APP;
CREATE CONTEXT CTX_APP_FLT USING PKG_APP;
```

### 13.2 Popolo Contesti in Inizializza

```sql
PKG_APP.AggiungiContesto('CTX_APP_IDS', 'ID_SESSIONE', gSessione.IdSessione);
PKG_APP.AggiungiContesto('CTX_APP_IDS', 'ID_PROFILO', gProfilo.IdProfilo);
PKG_APP.AggiungiContesto('CTX_APP_IDS', 'ID_RUOLO', gProfilo.IdRuolo);
PKG_APP.AggiungiContesto('CTX_APP_IDS', 'ID_UTENTE', gUtente.IdUtente);

PKG_APP.AggiungiContesto('CTX_APP_ABL', 'ABILITAZIONI', vAbilitazioniJSON);
```

---

## 14. Connessione Dati

### 14.1 Tabelle Principali

| Tabella | Scopo |
|---------|--------|
| `UTENTI` | Credenziali utente (LOGIN, PASSWORD_0) |
| `PROFILI` | Profili utente con assegnazione ruolo |
| `RUOLI` | Definizione ruoli del sistema |
| `TBL_AZIONI` | Tipi di azione (INSERIMENTO, MODIFICA, etc) |
| `TBL_PRIVILEGI` | Mappature azione-ruolo |
| `TBL_SESSIONI` | Sessioni attive |
| `TBL_ACCESSI` | Log degli accessi |
| `ANAGRAFE` | Dati anagrafici assistiti |
| `PRESE_IN_CARICO` | Prese in carico domiciliari/residenziali |
| `VALUTAZIONI_UVG` | Valutazioni sanitarie |
| `LISTA_ATTESA_RESIDENZIALE` | Liste attesa strutture |
| `PROGRESSIVI_LATTEA` | Contatori codici clinici |

### 14.2 Sequenze

- `PROFILI_ID_PROFILO` - Generazione ID profili
- `UTENTI_ID_UTENTE` - Generazione ID utenti
- `[altre sequenze per ogni tabella]`

---

## 15. Best Practices

### 15.1 Creazione Nuovo Dominio

Per aggiungere un nuovo dominio (es. OBJ_Ricoveri):

1. **Crea il tipo**:
   ```sql
   CREATE OR REPLACE TYPE OBJ_Ricoveri UNDER OBJ_Profilatore (
     IdRicovero NUMBER,
     IdAssistito NUMBER,
     IdStruttura NUMBER,
     DataInizio DATE,
     DataFine DATE,
     Diagnosi VARCHAR2(512),
     DataIns DATE, UtenteIns NUMBER,
     DataAgg DATE, UtenteAgg NUMBER,
     Attivo VARCHAR2(1),
     OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
     STATIC FUNCTION Carica(pIdRicovero IN NUMBER) RETURN OBJ_Ricoveri,
     MEMBER FUNCTION ControlliLogici RETURN BOOLEAN,
     MEMBER PROCEDURE Crea,
     MEMBER PROCEDURE Modifica,
     MEMBER PROCEDURE Elimina,
     CONSTRUCTOR FUNCTION OBJ_Ricoveri RETURN SELF AS RESULT
   );
   ```

2. **Implementa il TYPE BODY** con pattern CRUD

3. **Aggiungi azioni in TBL_AZIONI**:
   ```sql
   INSERT INTO TBL_AZIONI (TIPO, OGGETTO, AMBITO) 
   VALUES ('INSERIMENTO', 'RICOVERO', NULL);
   INSERT INTO TBL_AZIONI (TIPO, OGGETTO, AMBITO) 
   VALUES ('MODIFICA', 'RICOVERO', NULL);
   etc.
   ```

4. **Assegna privilegi in TBL_PRIVILEGI**:
   ```sql
   INSERT INTO TBL_PRIVILEGI (ID_AZIONE, ID_RUOLO, ATTIVO)
   VALUES (IdAzione_RICOVERO_INSERT, IdRuolo_MEDICO, 'S');
   ```

5. **Crea package PKG_RICOVERI** per business logic se necessario

### 15.2 Aggiungi Nuova Azione/Ruolo

```sql
-- Aggiungere azione
INSERT INTO TBL_AZIONI (ID_AZIONE, TIPO, OGGETTO, AMBITO, ATTIVO)
VALUES (TBL_AZIONI_SEQ.NEXTVAL, 'ESPORTAZIONE', 'CARTELLA', 'AMMINISTRATIVO', 'S');

-- Aggiungere ruolo
INSERT INTO RUOLI (ID_RUOLO, NOME, DESCRIZIONE, ATTIVO)
VALUES (RUOLI_SEQ.NEXTVAL, 'SUPERVISORE', 'Ruolo supervisore', 'S');

-- Assegnare privilegio
INSERT INTO TBL_PRIVILEGI (ID_PRIVILEGIO, ID_AZIONE, ID_RUOLO, ATTIVO)
VALUES (TBL_PRIVILEGI_SEQ.NEXTVAL, IdAzione_ESPORTAZIONE, IdRuolo_SUPERVISORE, 'S');
```

### 15.3 Abilitazioni Specifiche (Row-Level Security)

```sql
-- Creare abilitazione per limitare a provincia
INSERT INTO ABILITAZIONI (ID_ABILITAZIONE, ID_PROFILO, CHIAVE, VALORE, OPERATORE)
VALUES (ABILITAZIONI_SEQ.NEXTVAL, IdProfilo, 'PROVINCIA', 'TO', '=');

-- In query, aggiungere:
-- WHERE ... AND PROVINCIA = PKG_APP.VisualizzaContesto('CTX_APP_ABL', 'PROVINCIA')
```

---

## 16. Troubleshooting

### 16.1 Errore: Sessione non inizializzata

**Sintomo**: `OBJ_Profilo.MioIdRuolo()` ritorna NULL

**Causa**: `PKG_APP.Inizializza()` non è stato chiamato o ha fallito

**Soluzione**:
```sql
BEGIN
  IF NOT PKG_APP.Inizializza('username', 'password', pIdProfilo) THEN
    DBMS_OUTPUT.PUT_LINE('Errore login');
  END IF;
END;
```

### 16.2 Errore: Privilegio mancante (401)

**Sintomo**: Operazione negata con `Esito.StatusCode = 401`

**Causa**: L'azione non è mappata al ruolo in TBL_PRIVILEGI

**Soluzione**:
```sql
-- Verifica privilegi
SELECT * FROM TBL_PRIVILEGI PR
WHERE PR.ID_AZIONE = (SELECT ID_AZIONE FROM TBL_AZIONI 
                       WHERE TIPO='INSERIMENTO' AND OGGETTO='PROFILO')
  AND PR.ID_RUOLO = PKG_PROXY.gIdRuolo
  AND PR.ATTIVO = 'S';

-- Se non trovato, aggiungere:
INSERT INTO TBL_PRIVILEGI (ID_AZIONE, ID_RUOLO, ATTIVO)
VALUES (..., PKG_PROXY.gIdRuolo, 'S');
```

### 16.3 Errore: OBJ_Condizioni non inizializzato

**Sintomo**: Exception su OBJ_Condizioni null

**Causa**: Constructor non chiama `SELF.Condizioni := OBJ_Condizioni();`

**Soluzione**: Verificare che ogni TYPE BODY abbia nel constructor:
```sql
CONSTRUCTOR FUNCTION OBJ_Profilo RETURN SELF AS RESULT IS
BEGIN
  -- ... altri campi ...
  SELF.Condizioni := OBJ_Condizioni();  -- IMPORTANTE
  RETURN;
END;
```

### 16.4 Password Scadenza

**Sintomo**: Login fallisce sebbene credenziali corrette

**Causa**: `U.DATA_SCADENZA_PASSWORD < SYSDATE`

**Soluzione**: Aggiornare in UTENTI:
```sql
UPDATE UTENTI
SET DATA_SCADENZA_PASSWORD = SYSDATE + 90
WHERE ID_UTENTE = idUtente;
COMMIT;
```

---

## 17. Glossario

| Termine | Significato |
|---------|-------------|
| **AAA** | Authentication, Authorization, Accounting |
| **RLS** | Row-Level Security - Filtri per limitare visibilità dati |
| **OBJ_*** | Type / Tipo di dato custom in PL/SQL |
| **PKG_*** | Package / Pacchetto PL/SQL |
| **CRUD** | Create, Read, Update, Delete |
| **Soft Delete** | Marcare come inattivo (Attivo='N') invece di cancellare fisicamente |
| **Profilazione** | Applicazione di filtri di sicurezza basati su ruolo/abilitazioni |
| **Contesto** | Oracle Application Context per variabili globali di sessione |
| **GUID** | Globally Unique Identifier = SYS_GUID() |
| **FK** | Foreign Key - Chiave esterna |
| **PK** | Primary Key - Chiave primaria |
| **ROWTYPE** | %ROWTYPE - Tipo record corrispondente a riga di tabella |

---

## 18. Conclusione

SISTER è un'architettura enterprise healthcare robusta che implementa:

✅ **Autenticazione forte** - MD5 hash + scadenza password  
✅ **Autorizzazione granulare** - Azione + Ruolo + Abilitazioni  
✅ **Accounting completo** - Log accessi e audit trail  
✅ **Row-Level Security** - Filtri JSON per dati sensibili  
✅ **Object-Oriented** - Type system per type safety  
✅ **Scalabilità** - Soft deletes e indici su campi critici  
✅ **Manutenibilità** - Pattern CRUD uniforme, naming conventions  

Per domande su specifici moduli, consultare i file sorgente comentati nella cartella `OBJ/` e `PKG/`.

---

**Fine Documentazione Tecnica**  
Data: 3 Febbraio 2026  
Versione: 1.0
