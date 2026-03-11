----------------------------------------------------------------------------
-- OBJ_Esito — Tipo Oracle per la gestione strutturata dei risultati operativi
--
-- Rappresenta il risultato di un'operazione: stato HTTP, messaggio,
-- lista errori e informazioni di debug.
--
-- SCOPO
--   Tipo di ritorno standard per tutti i metodi CRUD e di servizio della
--   libreria SISTER. Garantisce uniformita nelle risposte, sia per chiamate
--   interne PL/SQL sia per esposizione tramite ORDS.
--
-- DIPENDENZE CIRCOLARI
--   Il metodo Log() scrive in CTX_APP_LOG usando esclusivamente primitive
--   Oracle (UTL_CALL_STACK, DBMS_SESSION, SYS_CONTEXT) senza dipendere da
--   PKG_APP. Questo rompe il riferimento circolare:
--     OBJ_Esito → campo di OBJ_Profilatore
--                → base di tutti i sottotipi
--                  → usati da PKG_APP
--                    → (ex) chiamato da OBJ_Esito   -- ELIMINATO
--
-- UTILIZZO STANDARD nei metodi CRUD e in PKG_APP.VerificaAccesso:
--   vEsito := OBJ_Esito.Imposta(401, 'Non autorizzato', 'dettaglio', 'debug');
--   vEsito.Log();   -- scrive in CTX_APP_LOG e aggiorna il contatore progressivo
--   RETURN vEsito;
--
-- FORMATO VOCE IN CTX_APP_LOG
--   chiave : LOG_0000001, LOG_0000002, ...  (padding 7 cifre per ordinamento
--            lessicografico = cronologico)
--   valore : {"contatore":N,"livello":"INFO|WARN|ERROR","status":NNN,
--             "messaggio":"...","posizione":"...","errori":[...]}
--
-- CODICI HTTP UTILIZZATI
--   200 = Successo            201 = Creato
--   400 = Dati non validi     401 = Non autorizzato
--   403 = Accesso vietato     404 = Risorsa non trovata
--   409 = Conflitto           500 = Errore interno del server
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Esito AS OBJECT (
  StatusCode   NUMBER,          -- Stato HTTP: 200, 201, 400, 401, 403, 404, 409, 500, ...
  Messaggio    VARCHAR2(512),   -- Descrizione sintetica dell'esito
  Errori       CLOB,            -- Lista errori in formato JSON  (NULL se nessun errore)
  DebugInfo    VARCHAR2(4000),  -- Posizione nel codice e info di debug non sensibili
  CONSTRUCTOR FUNCTION OBJ_Esito RETURN SELF AS RESULT,
  STATIC FUNCTION Imposta(
    pStatusCode IN NUMBER,
    pMessaggio  IN VARCHAR2,
    pErrore     IN VARCHAR2,
    pDebugInfo  IN VARCHAR2
  ) RETURN OBJ_Esito,
  MEMBER PROCEDURE Log,
  MEMBER FUNCTION IsSuccess  RETURN BOOLEAN,
  MEMBER FUNCTION IsError    RETURN BOOLEAN,
  MEMBER FUNCTION GetMessage RETURN VARCHAR2,
  MEMBER FUNCTION Info       RETURN VARCHAR2
);

----------------------------------------------------------------------------

CREATE OR REPLACE TYPE BODY OBJ_Esito AS

  -- Costruttore: esito di default positivo (200 / 'Successo').
  -- Utilizzato quando si crea un oggetto senza specificare i campi,
  -- ad esempio prima di verificare l'esito di un'operazione successiva.
  CONSTRUCTOR FUNCTION OBJ_Esito RETURN SELF AS RESULT IS
  BEGIN
    SELF.StatusCode := 200;
    SELF.Messaggio  := 'Successo';
    SELF.Errori     := NULL;
    SELF.DebugInfo  := NULL;
    RETURN;
  END;


  -- Costruisce e restituisce un esito con i campi forniti.
  -- Non esegue logging: chiamare vEsito.Log() subito dopo se necessario.
  -- pErrore viene serializzato come array JSON nel campo Errori.
  --
  -- Parametri:
  --   pStatusCode (NUMBER)     — codice HTTP (es. 200, 400, 401, 500)
  --   pMessaggio  (VARCHAR2)   — messaggio sintetico leggibile dall'utente finale
  --   pErrore     (VARCHAR2)   — dettaglio tecnico (es. SQLERRM); serializzato in Errori
  --   pDebugInfo  (VARCHAR2)   — informazioni di debug non sensibili (posizione nel codice)
  --
  -- Esempio:
  --   SELF.Esito := OBJ_Esito.Imposta(200, 'Utente creato', NULL, NULL);
  --   SELF.Esito := OBJ_Esito.Imposta(401, 'Non autorizzato', SQLERRM, 'OBJ_Utente.Crea');
  STATIC FUNCTION Imposta(
    pStatusCode IN NUMBER,
    pMessaggio  IN VARCHAR2,
    pErrore     IN VARCHAR2,
    pDebugInfo  IN VARCHAR2
  ) RETURN OBJ_Esito IS
    vStatusCode NUMBER;
  BEGIN
    vStatusCode := NVL(pStatusCode, 500);

    RETURN OBJ_Esito(
      vStatusCode,
      NVL(pMessaggio, 'ERRORE GENERICO'),
      CASE WHEN pErrore IS NOT NULL
           THEN '[{"errore": "' || REPLACE(pErrore, '"', '\"') || '"}]'
           ELSE NULL
      END,
      pDebugInfo
    );
  END Imposta;


  -- Registra SELF in CTX_APP_LOG con chiave progressiva.
  --
  -- Non dipende da PKG_APP: usa direttamente le primitive Oracle.
  --   • posizione nel codice  →  UTL_CALL_STACK (risale di 3 livelli:
  --                               Log → chiamante di Log → chiamante del chiamante)
  --   • contatore progressivo →  SYS_CONTEXT('CTX_APP_PAR','LOG_CONTATORE')
  --                               incrementato con DBMS_SESSION.SET_CONTEXT
  --   • scrittura nel log     →  DBMS_SESSION.SET_CONTEXT su CTX_APP_LOG
  --
  -- Non solleva mai eccezioni: il logging non deve interrompere il flusso.
  MEMBER PROCEDURE Log IS
    vContatore  NUMBER;
    vChiave     VARCHAR2(128);
    vValore     VARCHAR2(4000);
    vLivello    VARCHAR2(10);
    vPosizione  VARCHAR2(512);
    vRiga       NUMBER;
    vSottoprog  VARCHAR2(256);
    vStatusCode NUMBER;
  BEGIN
    vStatusCode := NVL(SELF.StatusCode, 500);

    -- Risoluzione della posizione nel codice risalendo lo stack di 3 livelli:
    --   livello 1 = Log  |  livello 2 = chiamante di Log  |  livello 3 = chiamante del chiamante
    BEGIN
      vRiga      := UTL_CALL_STACK.UNIT_LINE(3);
      vSottoprog := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(
                      UTL_CALL_STACK.SUBPROGRAM(3)
                    );
      vPosizione := vSottoprog || ' [riga ' || vRiga || ']';
    EXCEPTION
      WHEN OTHERS THEN
        vPosizione := 'Posizione non disponibile';
    END;

    -- Determinazione del livello di log in base allo status HTTP
    vLivello := CASE
                  WHEN vStatusCode BETWEEN 200 AND 299 THEN 'INFO'
                  WHEN vStatusCode BETWEEN 400 AND 499 THEN 'WARN'
                  ELSE 'ERROR'
                END;

    -- Incremento contatore progressivo in CTX_APP_PAR usando DBMS_SESSION direttamente
    vContatore := NVL(TO_NUMBER(SYS_CONTEXT('CTX_APP_PAR', 'LOG_CONTATORE')), 0) + 1;
    DBMS_SESSION.SET_CONTEXT(
      namespace => 'CTX_APP_PAR',
      attribute => 'LOG_CONTATORE',
      value     => TO_CHAR(vContatore)
    );

    -- Chiave progressiva con padding a 7 cifre per ordinamento lessicografico corretto
    vChiave := 'LOG_' || LPAD(TO_CHAR(vContatore), 7, '0');

    -- Composizione del valore JSON della voce di log
    vValore := '{"contatore":'  || vContatore  ||
               ',"livello":"'   || vLivello    || '"' ||
               ',"status":'     || vStatusCode ||
               ',"messaggio":"' || REPLACE(NVL(SELF.Messaggio, ''), '"', '\"') || '"' ||
               ',"posizione":"' || REPLACE(vPosizione, '"', '\"') || '"' ||
               CASE WHEN SELF.Errori IS NOT NULL
                    THEN ',"errori":' || SUBSTR(SELF.Errori, 1, 500)
                    ELSE ''
               END || '}';

    -- Troncamento a 4000 caratteri (limite del contesto Oracle)
    IF LENGTH(vValore) > 4000 THEN
      vValore := SUBSTR(vValore, 1, 3997) || '...';
    END IF;

    -- Scrittura della voce in CTX_APP_LOG tramite DBMS_SESSION direttamente
    DBMS_SESSION.SET_CONTEXT(
      namespace => 'CTX_APP_LOG',
      attribute => vChiave,
      value     => vValore
    );

  EXCEPTION
    WHEN OTHERS THEN
      NULL; -- Il logging non deve mai interrompere il flusso principale
  END Log;


  -- Verifica se l'esito è positivo (status 2xx)
  MEMBER FUNCTION IsSuccess RETURN BOOLEAN IS
  BEGIN
    RETURN SELF.StatusCode BETWEEN 200 AND 299;
  END IsSuccess;


  -- Verifica se l'esito è un errore (status >= 400)
  MEMBER FUNCTION IsError RETURN BOOLEAN IS
  BEGIN
    RETURN SELF.StatusCode >= 400;
  END IsError;


  -- Restituisce il messaggio dell'esito
  MEMBER FUNCTION GetMessage RETURN VARCHAR2 IS
  BEGIN
    RETURN SELF.Messaggio;
  END GetMessage;


  -- Informazioni sull'oggetto
  MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'ESITO';
  END Info;

END;
