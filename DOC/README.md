# SISTER — Indice della Documentazione Tecnica

**Progetto**: SISTER — Sistema Informativo Sanitario Territoriale e Regionale
**Tecnologia**: Oracle 19c / PL/SQL Object-Oriented / ORDS
**Versione documentazione**: 0.5.0 — 2026-03-11

---

## Contenuto

### API e Integrazione

| File | Descrizione |
|------|-------------|
| [api/overview.md](api/overview.md) | Panoramica architetturale dell'API SISTER |
| [api/authentication.md](api/authentication.md) | Flusso di autenticazione e gestione sessione |
| [api/error-codes.md](api/error-codes.md) | Codici HTTP e messaggi di errore standard |

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
  ├── OBJ_Sessione    → TBL_SESSIONI
  ├── OBJ_Utente      → UTENTI
  ├── OBJ_Profilo     → PROFILI
  ├── OBJ_Ruolo       → TAB_RUOLI
  ├── OBJ_Azione      → TBL_AZIONI
  ├── OBJ_Privilegio  → TBL_PRIVILEGI
  └── OBJ_Abilitazione → ABILITAZIONI
```

---

## Convenzioni di Questa Documentazione

- I nomi degli endpoint, dei parametri e dei campi JSON sono in inglese
- Le descrizioni funzionali sono in italiano
- I placeholder sono indicati con `[NOME_PLACEHOLDER]`
- Gli esempi usano `curl` come strumento di riferimento
