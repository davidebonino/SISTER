# SISTER - Sistema Informativo Sanitario Territoriale e Regionale

## Panoramica
Progetto PL/SQL object-oriented per la gestione di accessi e profili in ambito sanitario su Oracle 19c con ORDS.

## Stack Tecnologico
- **Database**: Oracle Database 19c
- **Linguaggio**: PL/SQL Object-Oriented (Types con ereditarietà)
- **API**: ORDS (Oracle REST Data Services)
- **Sessione**: Oracle Application Context (DBMS_SESSION, SYS_CONTEXT)
- **Logging**: Contesto applicativo CTX_APP_LOG

## Struttura del Progetto
```
SRC/OBJ/          - Oracle TYPE objects (10 file .sql)
SRC/PKG/          - Package PL/SQL (PKG_APP.sql)
SRC/TEST_APP.sql  - Script di test
DOC/setup.md      - Documentazione principale (mantenere aggiornata)
DOC/DOCUMENTAZIONE_TECNICA.md  - IGNORARE (non aggiornata)
```

## Convenzioni di Naming
- **Prefissi oggetti**: `OBJ_` = Type, `PKG_` = Package, `CTX_` = App Context, `TBL_` = Tabelle DB
- **Nomi PL/SQL**: CamelCase senza underscore (es. `ObjSessione`, `BuildWhere`)
- **Variabili**: `g` = globale, `p` = parametro, `v` = locale
- **Tabelle DB**: UPPERCASE con underscore (preesistenti nel DB)

## Gerarchia Tipi
```
OBJ_Esito      (standalone - gestione risposte HTTP)
OBJ_Condizioni (standalone - filtri JSON)
OBJ_Profilatore (base - NOT FINAL)
  ├── OBJ_Sessione
  ├── OBJ_Utente
  ├── OBJ_Profilo
  ├── OBJ_Ruolo
  ├── OBJ_Azione
  ├── OBJ_Privilegio
  └── OBJ_Abilitazione
```

## Pattern di Codice
- **Costruttore**: ogni TYPE ha `CONSTRUCTOR FUNCTION` per inizializzare i campi
- **CRUD**: `Crea()`, `Modifica()`, `Elimina()` per ogni entità
- **Caricamento**: `Carica()` static function per caricare da DB
- **Verifica accesso**: ogni metodo CRUD chiama `PKG_APP.VerificaAccesso()` come prima istruzione (vedi sezione dedicata)
- **Soft delete**: campo `Attivo = 'S'|'N'` (Utente, Profilo, Privilegio — da estendere a Azione e Abilitazione)
- **Audit trail**: `DataIns`, `UtenteIns`, `DataAgg`, `UtenteAgg`
- **HTTP status**: 200=OK, 201=Creato, 400=BadRequest, 401=NonAutorizzato, 403=Vietato, 500=Errore
- **Eccezioni WHEN OTHERS**: restituire sempre 500 (non 404)

## Pattern Verifica Accesso CRUD

Ogni metodo `Crea`, `Modifica`, `Elimina` (e `Carica` con privilegio specifico) usa questo pattern:

```plsql
MEMBER PROCEDURE Crea IS
  vEsitoAccesso OBJ_Esito;
BEGIN
  vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'OGGETTO', NULL, SELF.ControlliLogici());
  IF vEsitoAccesso.StatusCode <> 200 THEN
    SELF.Esito := vEsitoAccesso;
    RETURN;
  END IF;
  -- DML ...
  SELF.Esito := OBJ_Esito.Imposta(200, '...', NULL, NULL);
EXCEPTION
  WHEN OTHERS THEN
    SELF.Esito := OBJ_Esito.Imposta(500, '...', SQLERRM, SQLERRM);
END Crea;
```

**Regole:**
- `Crea` / `Modifica`: passare `SELF.ControlliLogici()` come 4° parametro
- `Elimina`: passare `TRUE` (i controlli logici non si applicano alle eliminazioni)
- `VerificaAccesso` gestisce internamente: autenticazione (401) → ricerca azione (401) → verifica privilegio (401) → controlli logici (400)
- **Non** replicare manualmente questi controlli: eliminare `vIdPrivilegio`, `OBJ_Privilegio.Cerca()`, `OBJ_Azione.Cerca()` dai metodi CRUD

**Eccezione — `Carica()` chiamato durante `Inizializza()`:**
I metodi `OBJ_Utente.Carica`, `OBJ_Profilo.Carica`, `OBJ_Azione.Carica(pIdAzione)` usano solo `IF MioIdRuolo() IS NOT NULL` senza `VerificaAccesso`, perché vengono invocati da `PKG_APP.Inizializza()` prima che il contesto sia completamente popolato.

## Flusso di Autenticazione
1. `PKG_APP.Inizializza(username, password, profileId)`
2. `OBJ_Sessione.Crea()` — valida credenziali, crea sessione in TBL_SESSIONI
3. `OBJ_Profilo.Carica()` — carica profilo e ruolo
4. `OBJ_Profilo.CaricaContestoAbilitazioni()` — carica abilitazioni in CTX_APP_ABL
5. `OBJ_Utente.Carica()` — carica dettagli utente
6. Contesto sessione: `CTX_APP_IDS` (ID_SESSIONE, ID_PROFILO, ID_RUOLO, ID_UTENTE)

## Note Importanti
- Non usare schema esplicito `SISTER_TST.` nel codice
- Le tabelle `CTX_*` (es. `ctx_column_map`) si considerano esistenti nel DB
- Componenti documentati ma non ancora presenti: PKG_AAA, PKG_ANA, PKG_DOM, PKG_RES, PKG_AURA, cartelle FN/, SP/, PROC/, PKG/TEST/
- Sviluppo futuro: convertire Azione e Abilitazione a soft delete (allineare a pattern Utente/Profilo/Privilegio)

## Lingua
Tutta la comunicazione, il codice e la documentazione sono in **italiano**.
