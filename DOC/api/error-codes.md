# SISTER — Codici di Errore e Messaggi Standard

**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Struttura della Risposta OBJ_Esito

Ogni operazione SISTER restituisce un oggetto `OBJ_Esito` con i seguenti campi:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `StatusCode` | NUMBER | Codice HTTP che indica l'esito dell'operazione |
| `Messaggio` | VARCHAR2(512) | Descrizione sintetica leggibile dall'utente |
| `Errori` | CLOB | Lista errori in formato JSON (NULL se successo) |
| `DebugInfo` | VARCHAR2(4000) | Informazioni tecniche di debug (posizione nel codice) |

### Formato JSON degli Errori

```json
[{"errore": "ORA-01403: no data found"}]
```

---

## Tabella Codici HTTP

| Codice | Nome HTTP | Quando viene restituito |
|--------|-----------|------------------------|
| **200** | OK | Operazione completata con successo |
| **201** | Created | Risorsa creata con successo (es. nuova sessione, nuovo record) |
| **204** | No Content | Risorsa non trovata per i parametri forniti (nessun dato) |
| **400** | Bad Request | Dati non validi; controlli logici falliti; sinonimo non riconosciuto in BuildWhere |
| **401** | Unauthorized | Sessione non attiva; azione non configurata; privilegio insufficiente per il ruolo |
| **403** | Forbidden | Accesso esplicitamente negato (uso futuro) |
| **404** | Not Found | Record non trovato per operazioni di modifica/eliminazione (UPDATE/DELETE con 0 righe) |
| **409** | Conflict | Conflitto (uso futuro, es. duplicato) |
| **500** | Internal Server Error | Errore non previsto (WHEN OTHERS); SQLERRM incluso in Errori e DebugInfo |

---

## Messaggi Standard per Entità

### OBJ_Sessione

| Operazione | StatusCode | Messaggio |
|------------|------------|-----------|
| Crea — successo | 201 | `Sessione creata con successo` |
| Crea — credenziali errate | 401 | `Autenticazione non riuscita, parametri errati` |
| Crea — IdRuolo non valido | 401 | `Autenticazione non riuscita, IdRuolo non valido` |
| Crea — errore interno | 500 | `Autenticazione non riuscita per errore interno` |
| Carica — successo | 200 | `Sessione caricata con successo` |
| Carica — non trovata | 204 | `Sessione non trovata, parametri errati` |
| Carica — errore interno | 500 | `Sessione non trovata per errore interno` |

### OBJ_Utente

| Operazione | StatusCode | Messaggio |
|------------|------------|-----------|
| Crea — successo | 200 | `Utente creato con successo` |
| Crea — errore interno | 500 | `Utente non inserito per errore interno` |
| Modifica — successo | 200 | `Utente modificato con successo` |
| Modifica — non trovato | 404 | `Utente non trovato per modifica` |
| Modifica — errore interno | 500 | `Utente non modificato per errore interno` |
| Elimina — successo | 200 | `Utente eliminato con successo` |
| Elimina — non trovato | 404 | `Utente non trovato per eliminazione` |
| Elimina — errore interno | 500 | `Utente non eliminato per errore interno` |
| Carica — successo | 200 | `Utente caricato con successo` |
| Carica — non trovato | 204 | `Utente non trovato` |
| Carica — non autorizzato | 401 | `Chiamante non autorizzato` |
| Carica — errore interno | 500 | `Utente non trovato per errore interno` |

### OBJ_Profilo

| Operazione | StatusCode | Messaggio |
|------------|------------|-----------|
| Crea — successo | 200 | `Profilo creato con successo` |
| Crea — errore interno | 500 | `Profilo non inserito per errore interno` |
| Modifica — successo | 200 | `Profilo modificato con successo` |
| Modifica — non trovato | 404 | `Profilo non trovato per modifica` |
| Elimina — successo | 200 | `Profilo eliminato con successo` |
| Elimina — non trovato | 404 | `Profilo non trovato per eliminazione` |
| Carica — successo | 200 | `Profilo caricato con successo` |
| Carica — non trovato | 204 | `Profilo non trovato` |

### OBJ_Azione

| Operazione | StatusCode | Messaggio |
|------------|------------|-----------|
| Crea — successo | 200 | `Azione creata con successo` |
| Crea — errore interno | 500 | `Azione non inserita per errore interno` |
| Modifica — successo | 200 | `Azione modificata con successo` |
| Modifica — non trovata | 404 | `Azione non trovata per modifica` |
| Elimina — successo | 200 | `Azione eliminata con successo` |
| Elimina — non trovata | 404 | `Azione non trovata per eliminazione` |
| Carica — successo | 200 | `Azione caricata con successo` |
| Carica — non trovata | 204 | `Azione non trovata` |

### OBJ_Privilegio

| Operazione | StatusCode | Messaggio |
|------------|------------|-----------|
| Crea — successo | 200 | `Privilegio creato con successo` |
| Crea — errore interno | 500 | `Privilegio non inserito per errore interno` |
| Modifica — successo | 200 | `Privilegio modificato con successo` |
| Modifica — non trovato | 404 | `Privilegio non trovato per modifica` |
| Elimina — successo | 200 | `Privilegio eliminato con successo` |
| Elimina — non trovato | 404 | `Privilegio non trovato per eliminazione` |
| Carica — successo | 200 | `Privilegio caricato con successo` |
| Carica — non trovato | 204 | `Privilegio non trovato` |

### OBJ_Abilitazione

| Operazione | StatusCode | Messaggio |
|------------|------------|-----------|
| Crea — successo | 200 | `Abilitazione creata con successo` |
| Crea — errore interno | 500 | `Abilitazione non inserita per errore interno` |
| Modifica — successo | 200 | `Abilitazione modificata con successo` |
| Modifica — non trovata | 404 | `Abilitazione non trovata per modifica` |
| Elimina — successo | 200 | `Abilitazione eliminata con successo` |
| Elimina — non trovata | 404 | `Abilitazione non trovata per eliminazione` |
| Carica — successo | 200 | `Abilitazione caricata con successo` |
| Carica — non trovata | 204 | `Abilitazione non trovata, parametri errati` |

---

## Messaggi di Verifica Accesso (PKG_APP.VerificaAccesso)

| Condizione | StatusCode | Messaggio |
|------------|------------|-----------|
| Sessione non inizializzata | 401 | `[Oggetto] non [azione], autenticazione mancante` |
| Azione non configurata | 401 | `[Oggetto] non [azione], azione non configurata` |
| Privilegio mancante | 401 | `[Oggetto] non [azione], privilegi insufficienti` |
| Controlli logici falliti | 400 | `[Oggetto] non [azione], errori nei controlli logici` |
| Accesso consentito | 200 | `Accesso consentito` |
| Errore interno | 500 | `Verifica accesso non riuscita per errore interno` |

Dove `[Oggetto]` è il nome dell'entità (es. `Utente`) e `[azione]` è il tipo in minuscolo
(es. `inserimento`, `modifica`, `eliminazione`).

**Esempio**:
```json
{
  "StatusCode": 401,
  "Messaggio":  "Utente non inserimento, autenticazione mancante",
  "Errori":     [{"errore": "MioIdRuolo IS NULL"}],
  "DebugInfo":  "PKG_APP.VerificaAccesso: INSERIMENTO su UTENTE"
}
```

---

## Messaggi di BuildWhere (OBJ_Profilatore.BuildWhere)

| Condizione | StatusCode | Messaggio |
|------------|------------|-----------|
| Completata senza avvisi | 200 | `BuildWhere completata` |
| FLT allarga visibilità | 200 | `BuildWhere completata con avvisi` |
| Sinonimo non mappato | 400 | `BuildWhere: sinonimo non riconosciuto` |
| Errore interno | 500 | `BuildWhere non riuscita per errore interno` |

Nota: con StatusCode 200 e avvisi, il campo `Errori` contiene il messaggio
`FLT allarga visibilità per: [lista attributi]`.

---

## Gestione degli Errori nei Client

### PL/SQL

```plsql
DECLARE
  vUtente OBJ_Utente;
BEGIN
  vUtente := OBJ_Utente();
  vUtente.Login   := 'nuovo.utente';
  vUtente.Cognome := 'Rossi';
  vUtente.Crea();

  -- Verifica sempre il StatusCode prima di procedere
  IF vUtente.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('OK: ' || vUtente.Esito.Messaggio);
    COMMIT;
  ELSIF vUtente.Esito.StatusCode = 401 THEN
    DBMS_OUTPUT.PUT_LINE('Accesso negato: ' || vUtente.Esito.Messaggio);
    ROLLBACK;
  ELSIF vUtente.Esito.StatusCode = 400 THEN
    DBMS_OUTPUT.PUT_LINE('Dati non validi: ' || vUtente.Esito.Messaggio);
    ROLLBACK;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore: ' || vUtente.Esito.StatusCode ||
                         ' - ' || vUtente.Esito.Messaggio);
    IF vUtente.Esito.DebugInfo IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('Debug: ' || vUtente.Esito.DebugInfo);
    END IF;
    ROLLBACK;
  END IF;
END;
```

### JavaScript (fetch via ORDS)

```javascript
const response = await fetch(`${ORDS_BASE_URL}/sister/utenti`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ login: 'nuovo.utente', cognome: 'Rossi' })
});

const data = await response.json();

if (data.status_code === 200) {
  console.log('Successo:', data.messaggio);
} else if (data.status_code === 401) {
  console.error('Non autorizzato:', data.messaggio);
  // reindirizzare al login
} else {
  console.error(`Errore ${data.status_code}: ${data.messaggio}`);
  if (data.errori) {
    data.errori.forEach(e => console.error('Dettaglio:', e.errore));
  }
}
```

---

[← Torna all'indice](../README.md)
