# SISTER — Guida Rapida all'Integrazione

**Versione**: 0.5.0
**Data**: 2026-03-11

---

## Prerequisiti

Prima di utilizzare la libreria SISTER è necessario:

1. **Database Oracle 19c** con schema dedicato (es. `SISTER_TST`)
2. **ORDS installato e configurato** sullo schema Oracle
3. **Contesti Oracle creati** (una volta sola, come DBA):
   ```sql
   CREATE CONTEXT CTX_APP_IDS USING PKG_APP;
   CREATE CONTEXT CTX_APP_PAR USING PKG_APP;
   CREATE CONTEXT CTX_APP_ABL USING PKG_APP;
   CREATE CONTEXT CTX_APP_FLT USING PKG_APP;
   CREATE CONTEXT CTX_APP_LOG USING PKG_APP;
   ```
4. **Tabelle del database** esistenti (`UTENTI`, `PROFILI`, `TBL_SESSIONI`,
   `TBL_AZIONI`, `TBL_PRIVILEGI`, `ABILITAZIONI`, `TAB_RUOLI`)
5. **Dati di configurazione** in `TBL_AZIONI` e `TBL_PRIVILEGI` per le
   operazioni che si vogliono autorizzare

---

## Ordine di Compilazione

Compilare i file nell'ordine seguente (TYPE SPEC prima di TYPE BODY):

```
1.  OBJ_ESITO.sql          (TYPE + BODY)
2.  OBJ_PROFILATORE.sql    (TYPE + BODY)
3.  OBJ_RUOLO.sql          (TYPE + BODY)
4.  OBJ_SESSIONE.sql       (TYPE + BODY)
5.  OBJ_UTENTE.sql         (TYPE + BODY)
6.  OBJ_AZIONE.sql         (TYPE + BODY)
7.  OBJ_PRIVILEGIO.sql     (TYPE + BODY)
8.  OBJ_ABILITAZIONE.sql   (TYPE + BODY)
9.  OBJ_PROFILO.sql        (TYPE + BODY)
10. PKG_APP.sql            (SPEC + BODY)
```

> I TYPE SPEC di tutti gli oggetti devono essere compilati **prima** dei TYPE BODY
> per consentire a Oracle di risolvere le dipendenze forward.

---

## Scenario 1: Utilizzo PL/SQL Interno

### Passo 1 — Login

```plsql
DECLARE
  vOk BOOLEAN;
BEGIN
  -- Inizializza la sessione: autentica, carica profilo e abilitazioni
  vOk := PKG_APP.Inizializza(
    pUsername  => 'mario.rossi',
    pKeyword   => 'MiaPassword',
    pIdProfilo => 17460
  );

  IF NOT vOk THEN
    RAISE_APPLICATION_ERROR(-20001, 'Login fallito');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Sessione avviata');
  DBMS_OUTPUT.PUT_LINE('ID_UTENTE: ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE'));
  DBMS_OUTPUT.PUT_LINE('ID_RUOLO:  ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO'));
END;
```

### Passo 2 — Operazione CRUD

```plsql
DECLARE
  vUtente OBJ_Utente;
BEGIN
  -- Carica un utente esistente
  vUtente := OBJ_Utente.Carica(237);

  IF vUtente.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('Utente: ' || vUtente.Cognome || ' ' || vUtente.Nome);

    -- Modifica il cognome
    vUtente.Cognome := 'Cognome Aggiornato';
    vUtente.Modifica();

    IF vUtente.Esito.StatusCode = 200 THEN
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Modifica OK');
    ELSE
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Modifica fallita: ' || vUtente.Esito.Messaggio);
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Utente non trovato: ' || vUtente.Esito.Messaggio);
  END IF;
END;
```

### Passo 3 — Query con Filtri Automatici (BuildWhere)

```plsql
DECLARE
  vUtente OBJ_Utente;
  vWhere  VARCHAR2(32767);
  vSql    VARCHAR2(32767);
BEGIN
  -- Imposta i filtri di ricerca aggiuntivi nel contesto FLT
  PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'B%|LIKE');
  PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO',  'S|=');

  -- BuildWhere combina CTX_APP_ABL (dal profilo) con CTX_APP_FLT (ricerca)
  vUtente := OBJ_Utente();
  vUtente.BuildWhere('U', vWhere);

  IF vUtente.Esito.StatusCode = 200 THEN
    DBMS_OUTPUT.PUT_LINE('WHERE generata: ' || vWhere);
    -- Esempio output: "U.ATTIVO = 'S' AND U.COGNOME LIKE 'B%'"

    -- Usa la clausola in una query
    vSql := 'SELECT * FROM UTENTI U WHERE ' || vWhere;
    -- EXECUTE IMMEDIATE vSql BULK COLLECT INTO ...
  ELSE
    DBMS_OUTPUT.PUT_LINE('BuildWhere errore: ' || vUtente.Esito.Messaggio);
  END IF;

  -- Pulizia filtri al termine
  PKG_APP.PulisciContesto('CTX_APP_FLT');
END;
```

---

## Scenario 2: Integrazione via REST (ORDS)

### Passo 1 — Login

```bash
TOKEN=$(curl -s -X POST https://[ORDS_BASE_URL]/sister/sessioni/login \
  -H "Content-Type: application/json" \
  -d '{"username":"mario.rossi","password":"MiaPassword","id_profilo":17460}' \
  | jq -r '.id_sessione')

echo "Token sessione: $TOKEN"
```

### Passo 2 — Operazione CRUD

```bash
# Crea un nuovo utente
curl -X POST https://[ORDS_BASE_URL]/sister/utenti \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: $TOKEN" \
  -d '{
    "login":   "nuovo.utente",
    "cognome": "Bianchi",
    "nome":    "Carlo",
    "email":   "carlo.bianchi@example.com"
  }'
```

### Passo 3 — Gestione Errori

```javascript
// JavaScript/TypeScript
async function chiamataAPI(url, method, body) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-Session-Id': sessionToken
    },
    body: body ? JSON.stringify(body) : undefined
  });

  const data = await response.json();

  switch (data.status_code) {
    case 200:
    case 201:
      return data;  // successo
    case 401:
      // sessione scaduta o privilegio mancante
      throw new Error(`Non autorizzato: ${data.messaggio}`);
    case 400:
      // dati non validi
      throw new Error(`Dati non validi: ${data.messaggio}`);
    case 204:
      return null;  // risorsa non trovata
    default:
      throw new Error(`Errore ${data.status_code}: ${data.messaggio}`);
  }
}
```

---

## Scenario 3: Configurazione RBAC

Per configurare le autorizzazioni di un nuovo modulo:

### 1. Crea le azioni nel catalogo

```plsql
-- Dopo il login come amministratore
DECLARE
  vAzione OBJ_Azione;
BEGIN
  -- Azione: inserimento del nuovo oggetto
  vAzione := OBJ_Azione();
  vAzione.Tipo        := 'INSERIMENTO';
  vAzione.Nome        := 'Crea Documento';
  vAzione.Oggetto     := 'DOCUMENTO';
  vAzione.Ambito      := NULL;
  vAzione.Crea();
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Azione creata: ' || vAzione.IdAzione);
END;
```

### 2. Assegna i privilegi al ruolo

```plsql
DECLARE
  vPrivilegio OBJ_Privilegio;
BEGIN
  vPrivilegio := OBJ_Privilegio();
  vPrivilegio.IdAzione := [ID_AZIONE_APPENA_CREATA];
  vPrivilegio.IdRuolo  := [ID_RUOLO_TARGET];
  vPrivilegio.Crea();
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Privilegio: ' || vPrivilegio.IdPrivilegio);
END;
```

### 3. Configura le abilitazioni di visibilità

```plsql
DECLARE
  vAbl OBJ_Abilitazione;
BEGIN
  -- Il profilo 17460 può vedere solo documenti attivi
  vAbl := OBJ_Abilitazione();
  vAbl.IdProfilo := 17460;
  vAbl.Chiave    := 'STATO_DOCUMENTO';
  vAbl.Valore    := 'ATTIVO';
  vAbl.Operatore := '=';
  vAbl.Crea();
  COMMIT;
END;
```

---

## Verifica dello Stato dei Log

```plsql
-- Visualizza tutti i messaggi di log della sessione corrente
DECLARE
  vLog VARCHAR2(4000);
BEGIN
  FOR i IN 1..PKG_APP.GetContatorLog LOOP
    vLog := SYS_CONTEXT('CTX_APP_LOG',
            'LOG_' || LPAD(TO_CHAR(i), 7, '0'));
    IF vLog IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE(vLog);
    END IF;
  END LOOP;
END;
```

---

## Troubleshooting Comune

| Problema | Causa probabile | Soluzione |
|----------|-----------------|-----------|
| `401 autenticazione mancante` | `PKG_APP.Inizializza()` non chiamato | Chiamare Inizializza prima di qualsiasi CRUD |
| `401 azione non configurata` | Manca riga in TBL_AZIONI | Aggiungere l'azione con OBJ_Azione.Crea() |
| `401 privilegi insufficienti` | Manca riga in TBL_PRIVILEGI | Assegnare il privilegio con OBJ_Privilegio.Crea() |
| `400 sinonimo non riconosciuto` | Campo FLT non mappato in RisolviSinonimo | Aggiungere il mapping nel metodo RisolviSinonimo del tipo |
| `500 errore interno` | Constraint violation, ORA-* | Controllare il campo `DebugInfo` e `Errori` nell'Esito |
| CTX_APP_LOG vuoto | Log non scritto | Chiamare `vEsito.Log()` dopo `OBJ_Esito.Imposta()` negli errori |

---

[← Torna all'indice](../README.md)
