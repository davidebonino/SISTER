# Changelog

Tutte le modifiche rilevanti al progetto sono documentate in questo file.
Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/)
e il progetto segue il [Semantic Versioning](https://semver.org/lang/it/).

---

## [0.4.0] — 2026-03-03

### Aggiunto
- `OBJ_Esito`: nuovo `MEMBER PROCEDURE Log` che registra l'esito in `CTX_APP_LOG`
  con chiave progressiva; implementato usando esclusivamente primitive Oracle
  (`UTL_CALL_STACK`, `DBMS_SESSION`, `SYS_CONTEXT`) senza dipendenze da `PKG_APP`
- `TEST_APP.sql`: aggiunte tre procedure di test per `BuildWhere`:
  - `TBW1` — filtro singolo `COGNOME LIKE 'B%'` (operatore LIKE, VARCHAR2)
  - `TBW2` — filtro singolo `ATTIVO = 'S'` (operatore =, VARCHAR2)
  - `TBW3` — filtri multipli combinati `COGNOME LIKE + ATTIVO =` (verifica concatenazione AND)
  - Ogni test usa `SAVEPOINT`/`ROLLBACK TO SAVEPOINT` per il cleanup di `ctx_column_map`

### Modificato
- `OBJ_PROFILATORE.sql`: aggiunta documentazione inline completa alla funzione `BuildWhere`
  con descrizione delle 8 fasi dell'algoritmo (iterazione contesto, risoluzione colonna,
  validazione anti-injection, qualificazione alias, parsing formato `valore|OP|TIPO`,
  validazione operatore/tipo, costruzione predicato, accumulo AND)
- `PKG_APP.sql`: rimossa `PROCEDURE Log(pEsito IN OBJ_Esito)` dalla SPEC e dal BODY;
  tutte le chiamate `Log(vEsito)` in `VerificaAccesso` sostituite con `vEsito.Log()`
- `PKG_APP.sql`: `VerificaAccesso` ora usa variabile locale `vEsito` per chiamare
  `vEsito.Log()` prima di ogni `RETURN` sugli esiti di errore (400, 401, 500)

### Rimosso
- `OBJ_CONDIZIONI.sql`: file eliminato — tipo non più referenziato da nessun oggetto
- Rimosso `SELF.Condizioni := OBJ_Condizioni()` dai costruttori di tutti i sottotipi:
  `OBJ_Utente`, `OBJ_Profilo`, `OBJ_Ruolo`, `OBJ_Azione`, `OBJ_Privilegio`,
  `OBJ_Abilitazione`, `OBJ_Sessione`
- Rimosso il campo `Condizioni OBJ_Condizioni` dalla dichiarazione di `OBJ_Profilatore`

### Corretto
- `OBJ_Esito.Imposta()`: rimosso il blocco di logging che chiamava `PKG_APP.MiaPosizione()`,
  `PKG_APP.IncrementaContatorLog()` e `PKG_APP.AggiungiContesto()` — eliminato il
  riferimento circolare a livello di TYPE SPEC:
  `OBJ_Esito → PKG_APP → OBJ_Profilatore → OBJ_Esito` 🔴

---

## [0.3.0] — 2026-03-03

### Rimosso
- `OBJ_CONDIZIONI.sql`: rimozione avviata in questa versione, completata in 0.4.0
- Primo refactoring della gerarchia per eliminare dipendenze inutilizzate

---

## [0.2.0] — 2026-03-02

### Aggiunto
- Commenti inline ai principali metodi PL/SQL per migliorare la leggibilità
- File `CLAUDE.md` con istruzioni operative per l'assistente AI (contesto progetto,
  convenzioni, pattern di codice, roadmap)

---

## [0.1.0] — 2026-02-26

### Aggiunto
- Struttura iniziale del progetto: cartelle `SRC/OBJ/`, `SRC/PKG/`, `DOC/`
- Gerarchia di tipi Oracle OO: `OBJ_Profilatore` (base), `OBJ_Esito`, `OBJ_Sessione`,
  `OBJ_Utente`, `OBJ_Profilo`, `OBJ_Ruolo`, `OBJ_Azione`, `OBJ_Privilegio`,
  `OBJ_Abilitazione`, `OBJ_Condizioni`
- `PKG_APP.sql`: package principale con `Inizializza()` e `VerificaAccesso()`
- `TEST_APP.sql`: script di test integrato con procedure `TAZ1`, `TUT1`, `TPR1`,
  `TPV1`, `TAB1`, `TRU1`, `TSE1`

### Modificato
- Refactoring di `VerificaAccesso`: centralizzazione dei controlli autenticazione,
  verifica privilegi e validazione logica; eliminazione del boilerplate
  `OBJ_Azione.Cerca` + `OBJ_Privilegio.Cerca` nei singoli metodi CRUD

---

<!-- ISTRUZIONI PER L'AGGIORNAMENTO
     Aggiungere una nuova sezione in cima (dopo l'intestazione) ad ogni push.
     Formato sezione:
     ## [MAJOR.MINOR.PATCH] — YYYY-MM-DD
     ### Aggiunto | Modificato | Corretto | Rimosso | Deprecato
     - Descrizione sintetica della modifica
     Incremento versione:
       MAJOR → breaking change (firma pubblica, struttura TYPE SPEC)
       MINOR → nuova funzionalità retrocompatibile
       PATCH → bugfix o refactoring interno
-->