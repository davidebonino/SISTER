# SISTER — Sistema Informativo Sanitario Territoriale e Regionale

Libreria PL/SQL object-oriented per Oracle 19c che costituisce la base tecnologica per applicazioni gestionali in ambito sanitario.
Esposta tramite ORDS (Oracle REST Data Services) e chiamate PL/SQL interne, con output sempre strutturato tramite `OBJ_Esito`.

---

## Scopo

Il progetto fornisce i fondamenti per:

- **Autenticazione e gestione delle sessioni** utente
- **Controllo degli accessi RBAC** (ruoli, profili, privilegi, azioni)
- **Profilazione automatica delle query** tramite Application Context Oracle e mapping su `ctx_column_map`
- **Logging multi-livello** con buffer in `CTX_APP_LOG` e stack trace via `UTL_CALL_STACK`

---

## Stack Tecnologico

| Componente       | Tecnologia                                              |
|------------------|---------------------------------------------------------|
| Database         | Oracle 19c                                              |
| Linguaggio       | PL/SQL con Oracle Object Types (ereditarietà)           |
| REST API         | ORDS (Oracle REST Data Services)                        |
| Sessione         | Oracle Application Context (`DBMS_SESSION`, `SYS_CONTEXT`) |
| Sicurezza query  | `DBMS_ASSERT.SIMPLE_SQL_NAME`                           |
| Stack trace      | `UTL_CALL_STACK`                                        |

---

## Struttura dei File Sorgente

```
SISTER/
├── SRC/
│   ├── OBJ/                       # Oracle TYPE objects (PL/SQL OO)
│   │   ├── OBJ_ESITO.sql          # Risposta standard HTTP — standalone, nessuna dipendenza
│   │   ├── OBJ_PROFILATORE.sql    # Superclasse base NOT FINAL (BuildWhere, utility, contesti)
│   │   ├── OBJ_SESSIONE.sql       # Gestione sessione utente (autenticazione)
│   │   ├── OBJ_UTENTE.sql         # Entità utente con CRUD completo
│   │   ├── OBJ_PROFILO.sql        # Profilo utente e caricamento abilitazioni
│   │   ├── OBJ_RUOLO.sql          # Ruolo applicativo (solo Carica)
│   │   ├── OBJ_AZIONE.sql         # Azione (operazione eseguibile) con CRUD
│   │   ├── OBJ_PRIVILEGIO.sql     # Associazione ruolo-azione con CRUD
│   │   └── OBJ_ABILITAZIONE.sql   # Filtri di autorizzazione per profilo con CRUD
│   ├── PKG/
│   │   └── PKG_APP.sql            # Package principale: Inizializza(), VerificaAccesso()
│   └── TEST_APP.sql               # Script di test integrato (TAZ1, TUT1, TPR1, TPV1, TPV2,
│                                  # TPV3, TAB1, TRU1, TSE1, TBW1..TBW8)
└── DOC/
    ├── README.md                  # Indice documentazione tecnica
    ├── setup.md                   # Documentazione di setup e configurazione DB
    ├── DOCUMENTAZIONE_TECNICA.md  # [NON AGGIORNATA — ignorare; usare DOC/README.md]
    ├── api/                       # Documentazione REST API
    │   ├── overview.md            # Panoramica architettura API
    │   ├── authentication.md      # Flusso di autenticazione
    │   ├── error-codes.md         # Codici di errore standard
    │   └── endpoints/             # Endpoint per entità
    └── guide/
        └── getting-started.md    # Guida rapida all'integrazione
```

---

## Gerarchia dei Tipi

```
OBJ_Esito           (standalone — risposta HTTP; Log() usa built-in Oracle diretti)
OBJ_Profilatore     (base NOT FINAL — BuildWhere, utility, lettura contesti)
  ├── OBJ_Sessione
  ├── OBJ_Utente
  ├── OBJ_Profilo
  ├── OBJ_Ruolo
  ├── OBJ_Azione
  ├── OBJ_Privilegio
  └── OBJ_Abilitazione
```

Ogni sottotipo eredita da `OBJ_Profilatore` il campo `Esito OBJ_Esito` e tutti i metodi
di utilità (`MioIdUtente()`, `MioIdRuolo()`, `BuildWhere()`, ecc.).

---

## Ordine di Compilazione

L'ordine è imposto dalle dipendenze tra TYPE SPEC. Compilare sempre i TYPE SPEC prima dei TYPE BODY.

```
1.  OBJ_Esito           — nessuna dipendenza applicativa
2.  OBJ_Profilatore     — dipende da OBJ_Esito
3.  OBJ_Ruolo           — dipende da OBJ_Profilatore
4.  OBJ_Sessione        — dipende da OBJ_Profilatore
5.  OBJ_Utente          — dipende da OBJ_Profilatore
6.  OBJ_Azione          — dipende da OBJ_Profilatore, OBJ_Utente
7.  OBJ_Privilegio      — dipende da OBJ_Profilatore, OBJ_Utente
8.  OBJ_Abilitazione    — dipende da OBJ_Profilatore, OBJ_Utente
9.  OBJ_Profilo         — dipende da OBJ_Profilatore, OBJ_Abilitazione
10. PKG_APP             — dipende da tutti i tipi
```

> **Nota sui cicli di dipendenza**: i BODY di alcuni tipi si richiamano a vicenda
> tramite `PKG_APP` (es. `OBJ_Azione` ↔ `OBJ_Utente` via `PKG_APP.VerificaAccesso`).
> Oracle risolve questi cicli a runtime; è sufficiente compilare tutti i TYPE SPEC prima
> dei TYPE BODY e PKG_APP per ultimo.

---

## Test Disponibili in TEST_APP.sql

| Procedura | Oggetto testato | Operazioni |
|-----------|-----------------|------------|
| `TAZ1(pIdAzione)` | OBJ_Azione | Carica, Crea, Modifica, Elimina |
| `TUT1(pIdUtente)` | OBJ_Utente | Carica, Crea, Modifica, Elimina |
| `TPR1(pIdProfilo)` | OBJ_Profilo | Carica, Crea, Modifica, Elimina |
| `TPV1(pIdPrivilegio)` | OBJ_Privilegio | Carica, Crea, Modifica, Elimina |
| `TPV2(pIdAzione, pIdRuolo)` | OBJ_Privilegio | Soft delete e cancellazione fisica |
| `TPV3(pIdAzione, pIdRuolo)` | OBJ_Privilegio | Carica per coppia, Cerca |
| `TAB1(pIdSessione, pIdAbilitazione)` | OBJ_Abilitazione | Carica, Crea, Modifica, Elimina |
| `TRU1(pIdRuolo)` | OBJ_Ruolo | Carica |
| `TSE1(username, password, idProfilo)` | OBJ_Sessione | Crea, Carica |
| `TBW1()` | BuildWhere | FLT LIKE VARCHAR2 |
| `TBW2()` | BuildWhere | FLT = NUMBER |
| `TBW3()` | BuildWhere | FLT multipli AND |
| `TBW4()` | BuildWhere | ABL+FLT stesso valore (deduplicazione) |
| `TBW5()` | BuildWhere | ABL+FLT valori diversi (IN + avviso) |
| `TBW6()` | BuildWhere | Sinonimo non riconosciuto (errore 400) |
| `TBW7()` | BuildWhere | BETWEEN su NUMBER |
| `TBW8()` | BuildWhere | IS NOT NULL con alias tabella |

---

## Application Contexts

| Context         | Contenuto                                                                        |
|-----------------|----------------------------------------------------------------------------------|
| `CTX_APP_IDS`   | Identità di sessione: `ID_SESSIONE`, `ID_UTENTE`, `ID_PROFILO`, `ID_RUOLO`      |
| `CTX_APP_PAR`   | Parametri di sistema: livello debug, contatore log (`LOG_CONTATORE`)             |
| `CTX_APP_ABL`   | Filtri di autorizzazione del profilo (caricati all'avvio sessione)               |
| `CTX_APP_FLT`   | Filtri di ricerca aggiuntivi (impostati a runtime dal chiamante)                 |
| `CTX_APP_LOG`   | Buffer messaggi di log in formato JSON, chiavi progressive `LOG_0000001`, ...    |

Tutti i contesti sono di tipo `USING PKG_APP` e devono essere creati prima del primo utilizzo
tramite `PKG_APP.CreaContesto()` o con `CREATE CONTEXT ... USING PKG_APP`.

---

## Tabella di Configurazione: ctx_column_map

Mappa gli attributi dei contesti Oracle alle colonne fisiche delle tabelle, usata da
`OBJ_Profilatore.BuildWhere()` per costruire clausole WHERE dinamiche e sicure.

| Colonna       | Tipo           | Descrizione                              |
|---------------|----------------|------------------------------------------|
| `namespace`   | VARCHAR2(128)  | Nome del contesto Oracle (es. `CTX_APP_FLT`) |
| `attribute`   | VARCHAR2(128)  | Attributo del contesto (es. `COGNOME`)   |
| `table_name`  | VARCHAR2(128)  | Tabella/vista di destinazione (es. `UTENTI`) |
| `column_name` | VARCHAR2(128)  | Colonna fisica corrispondente (es. `COGNOME`) |

Viene letta (mai scritta) in produzione. I test `TBW1`/`TBW2`/`TBW3` inseriscono righe
di test e le annullano con `ROLLBACK TO SAVEPOINT`.

---

## Pattern CRUD

Ogni metodo `Crea`, `Modifica`, `Elimina` segue questo schema:

```plsql
MEMBER PROCEDURE Crea IS
  vEsitoAccesso OBJ_Esito;
BEGIN
  -- 1. Verifica accesso (autenticazione + privilegio + controlli logici)
  vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'OGGETTO', NULL, SELF.ControlliLogici());
  IF vEsitoAccesso.StatusCode <> 200 THEN
    SELF.Esito := vEsitoAccesso;
    RETURN;
  END IF;

  -- 2. DML
  INSERT INTO TBL_... VALUES (...);

  -- 3. Esito finale
  SELF.Esito := OBJ_Esito.Imposta(200, 'Oggetto creato', NULL, NULL);
EXCEPTION
  WHEN OTHERS THEN
    SELF.Esito := OBJ_Esito.Imposta(500, 'Errore interno', SQLERRM, SQLERRM);
END Crea;
```

Regole:
- `Crea` / `Modifica`: passare `SELF.ControlliLogici()` come 4° parametro
- `Elimina`: passare `TRUE` (nessun controllo logico sull'eliminazione)
- `Carica()` chiamato durante `PKG_APP.Inizializza()`: usa solo `IF MioIdRuolo() IS NOT NULL` senza `VerificaAccesso`

---

## Flusso di Autenticazione

```
PKG_APP.Inizializza(username, password, profileId)
  → OBJ_Sessione.Crea()                      — valida credenziali, inserisce in TBL_SESSIONI
  → OBJ_Profilo.Carica()                     — carica profilo e ruolo
  → OBJ_Profilo.CaricaContestoAbilitazioni() — popola CTX_APP_ABL
  → OBJ_Utente.Carica()                      — carica dettagli utente
  → popola CTX_APP_IDS con ID_SESSIONE, ID_PROFILO, ID_RUOLO, ID_UTENTE
```

---

## Logging

Il logging è gestito da `OBJ_Esito.Log()`, un MEMBER PROCEDURE che:

- **non dipende da `PKG_APP`** (elimina il riferimento circolare `OBJ_Esito → PKG_APP → OBJ_Esito`)
- usa direttamente `UTL_CALL_STACK` per la posizione nel codice
- usa direttamente `DBMS_SESSION.SET_CONTEXT` per scrivere in `CTX_APP_LOG` e aggiornare `LOG_CONTATORE`

Utilizzo standard nei metodi CRUD e in `VerificaAccesso`:

```plsql
vEsito := OBJ_Esito.Imposta(401, 'Non autorizzato', 'dettaglio', 'debug');
vEsito.Log();   -- scrive in CTX_APP_LOG, aggiorna contatore
RETURN vEsito;
```

---

## Convenzioni di Naming

| Elemento              | Convenzione         | Esempio              |
|-----------------------|---------------------|----------------------|
| Oracle Types          | `OBJ_` + PascalCase | `OBJ_Profilatore`    |
| Package               | `PKG_` + UPPER      | `PKG_APP`            |
| Tabelle fisiche DB    | UPPER_SNAKE         | `TBL_SESSIONI`       |
| Application Context   | `CTX_` + UPPER      | `CTX_APP_IDS`        |
| Variabili locali      | prefisso `v`        | `vEsitoAccesso`      |
| Parametri             | prefisso `p`        | `pIdUtente`          |
| Variabili globali     | prefisso `g`        | `gSessione`          |

---

## Lingua

Tutta la comunicazione, il codice e la documentazione sono in **italiano**.