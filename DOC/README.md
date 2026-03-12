# SISTER — Indice della Documentazione Tecnica

**Progetto**: SISTER — Sistema Informativo Sanitario Territoriale e Regionale
**Tecnologia**: Oracle 19c / PL/SQL Object-Oriented / ORDS
**Versione documentazione**: 0.8.0 — 2026-03-12

---

## Contenuto

### API e Integrazione

| File | Descrizione |
|------|-------------|
| [api/overview.md](api/overview.md) | Panoramica architetturale dell'API SISTER |
| [api/authentication.md](api/authentication.md) | Flusso di autenticazione e gestione sessione |
| [api/error-codes.md](api/error-codes.md) | Codici HTTP e messaggi di errore standard |
| [api/pkg-app.md](api/pkg-app.md) | `PKG_APP` — package principale: Inizializza, VerificaAccesso, gestione contesti, parametri |

### Documentazione Tipi Oracle (OBJ_*)

| File | Tipo | Descrizione |
|------|------|-------------|
| [api/obj-profilatore.md](api/obj-profilatore.md) | `OBJ_Profilatore` | Superclasse base: campo Esito, funzioni di sessione, BuildWhere |
| [api/obj-utente.md](api/obj-utente.md) | `OBJ_Utente` | CRUD completo, soft delete, ricerca profilata con `Cerca` |
| [api/obj-anagrafe.md](api/obj-anagrafe.md) | `OBJ_Anagrafe` | CRUD assistiti SSR, cancellazione fisica, 12 sinonimi BuildWhere, minimizzazione GDPR |

### Endpoint REST (ORDS)

| File | Entità | Operazioni |
|------|--------|------------|
| [api/endpoints/sessioni.md](api/endpoints/sessioni.md) | Sessioni | Login, logout, verifica |
| [api/endpoints/utenti.md](api/endpoints/utenti.md) | Utenti | CRUD completo |
| [api/endpoints/profili.md](api/endpoints/profili.md) | Profili | CRUD + abilitazioni |
| [api/endpoints/azioni.md](api/endpoints/azioni.md) | Azioni | CRUD catalogo RBAC |
| [api/endpoints/privilegi.md](api/endpoints/privilegi.md) | Privilegi | CRUD associazioni ruolo-azione |
| [api/endpoints/abilitazioni.md](api/endpoints/abilitazioni.md) | Abilitazioni | CRUD filtri di visibilità |

### Guide

| File | Descrizione |
|------|-------------|
| [guide/getting-started.md](guide/getting-started.md) | Guida rapida all'integrazione |

### Script di Test (`SRC/TEST_APP.sql`)

| Procedura | Entità / Ambito | Descrizione |
|-----------|-----------------|-------------|
| `TAZ1(pIdAzione)` | `OBJ_Azione` | CRUD completo: carica, crea, modifica, elimina |
| `TUT1(pIdUtente)` | `OBJ_Utente` | CRUD completo con soft delete |
| `TPR1(pIdProfilo)` | `OBJ_Profilo` | CRUD completo con soft delete |
| `TPV1(pIdPrivilegio)` | `OBJ_Privilegio` | CRUD singolo su un privilegio esistente |
| `TPV2(pIdAzione, pIdRuolo)` | `OBJ_Privilegio` | Verifica soft delete (default) e cancellazione fisica (`TRUE`) |
| `TPV3(pIdAzione, pIdRuolo)` | `OBJ_Privilegio` | Verifica `Carica(IdAzione, IdRuolo)` e `Cerca` con coppia valida e inesistente |
| `TAB1(pIdSessione, pIdAbilitazione)` | `OBJ_Abilitazione` | CRUD completo con delete fisico |
| `TRU1(pIdRuolo)` | `OBJ_Ruolo` | Lettura e stampa dei campi del ruolo |
| `TSE1(username, password, idProfilo)` | `OBJ_Sessione` | Creazione sessione e ricaricamento tramite GUID |
| `TBW1` | `BuildWhere` | FLT singolo: LIKE su VARCHAR2 |
| `TBW2` | `BuildWhere` | FLT singolo: `=` su NUMBER |
| `TBW3` | `BuildWhere` | FLT multipli: combinazione AND |
| `TBW4` | `BuildWhere` | ABL + FLT stesso campo e stesso valore: deduplicazione (nessun IN) |
| `TBW5` | `BuildWhere` | ABL + FLT stesso campo con valori diversi: IN clause + avviso di allargamento visibilità |
| `TBW6` | `BuildWhere` | Sinonimo non mappato: errore 400 e `pWhere = NULL` |
| `TBW7` | `BuildWhere` | Operatore `BETWEEN` su NUMBER |
| `TBW8` | `BuildWhere` | Operatore `NOTNULL` (IS NOT NULL) con alias tabella |
| `TBWP1(pIterazioni)` | `BuildWhere` — performance | Benchmark: 3 scenari (1 FLT, 5 FLT eterogenei, 5 ABL+5 FLT con overlap); misura in centesimi di secondo tramite `DBMS_UTILITY.GET_TIME`. Default: 100 iterazioni per scenario. |
| `TCER1` | `OBJ_Utente.Cerca` | Ricerca utenti con `COGNOME LIKE 'SA%'`: imposta `CTX_APP_FLT`, invoca `Cerca`, visualizza i risultati in forma tabellare con contatore. Attiva per default. |

### Documentazione Esistente

| File | Descrizione | Stato |
|------|-------------|-------|
| [setup.md](setup.md) | Setup e configurazione del database | Aggiornato |
| [DOCUMENTAZIONE_TECNICA.md](DOCUMENTAZIONE_TECNICA.md) | Documentazione tecnica completa (versione precedente) | Non aggiornata — usare i file in `api/` |

---

## Architettura in Sintesi

```
CLIENT (ORDS / PL/SQL interno)
         |
         v
PKG_APP.Inizializza()        -- autenticazione + popolamento contesti
PKG_APP.VerificaAccesso()    -- RBAC centralizzato (usato da tutti i CRUD)
         |
         v
OBJ_Profilatore (base)
  ├── OBJ_Sessione     → TBL_SESSIONI
  ├── OBJ_Utente       → UTENTI
  ├── OBJ_Profilo      → PROFILI
  ├── OBJ_Ruolo        → TAB_RUOLI
  ├── OBJ_Azione       → TBL_AZIONI
  ├── OBJ_Privilegio   → TBL_PRIVILEGI
  ├── OBJ_Abilitazione → ABILITAZIONI
  └── OBJ_Anagrafe     → ANAGRAFE  (modulo ANA)
```

---

## Convenzioni di Questa Documentazione

- I nomi degli endpoint, dei parametri e dei campi JSON sono in inglese
- Le descrizioni funzionali sono in italiano
- I placeholder sono indicati con `[NOME_PLACEHOLDER]`
- Gli esempi usano `curl` come strumento di riferimento
