----------------------------------------------------------------------------
-- Esito
-- Formato chiave in CTX_APP_LOG: LOG_0000001, LOG_0000002, ...
-- Il contatore progressivo e gestito in CTX_APP_PAR (LOG_CONTATORE).
-- Ricerca per indice:    WHERE attribute = 'LOG_0000005'
-- Recupero ultimo esito: WHERE attribute = 'LOG_' || LPAD(PKG_APP.GetContatorLog, 7, '0')
-- Tutti i log ordinati:  ORDER BY attribute (ordinamento lessicografico = cronologico)
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Esito AS OBJECT (
  StatusCode   NUMBER,          -- Stati HTTP: 200, 400, 401, 403, 404, 409, 500, ...
  Messaggio    VARCHAR2(512),   -- Descrizione sintetica dell'esito
  Errori       CLOB,            -- Lista errori in formato JSON
  DebugInfo    VARCHAR2(4000),  -- Posizione nel codice e info di debug non sensibili
  CONSTRUCTOR FUNCTION OBJ_Esito RETURN SELF AS RESULT,
  STATIC FUNCTION Imposta(
    pStatusCode IN NUMBER,
    pMessaggio  IN VARCHAR2,
    pErrore     IN VARCHAR2,
    pDebugInfo  IN VARCHAR2
  ) RETURN OBJ_Esito,
  MEMBER FUNCTION IsSuccess  RETURN BOOLEAN,
  MEMBER FUNCTION IsError    RETURN BOOLEAN,
  MEMBER FUNCTION GetMessage RETURN VARCHAR2,
  MEMBER FUNCTION Info       RETURN VARCHAR2
);

----------------------------------------------------------------------------

CREATE OR REPLACE TYPE BODY OBJ_Esito AS

  -- Costruttore: esito di default positivo
  CONSTRUCTOR FUNCTION OBJ_Esito RETURN SELF AS RESULT IS
  BEGIN
    SELF.StatusCode := 200;
    SELF.Messaggio  := 'Successo';
    SELF.Errori     := NULL;
    SELF.DebugInfo  := NULL;
    RETURN;
  END;


  -- Imposta l'esito con tutti i campi.
  -- Aggiunge automaticamente la posizione nel codice in DebugInfo.
  -- Registra sempre in CTX_APP_LOG con chiave progressiva da CTX_APP_PAR.
  STATIC FUNCTION Imposta(
    pStatusCode IN NUMBER,
    pMessaggio  IN VARCHAR2,
    pErrore     IN VARCHAR2,
    pDebugInfo  IN VARCHAR2
  ) RETURN OBJ_Esito IS
    vEsito      OBJ_Esito;
    vPosizione  VARCHAR2(512);
    vDebug      VARCHAR2(4000);
    vLivello    VARCHAR2(10);
    vContatore  NUMBER;
    vChiave     VARCHAR2(128);
    vValore     VARCHAR2(4000);
    vStatusCode NUMBER;
  BEGIN
    vStatusCode := NVL(pStatusCode, 500);

    -- Risale di 3 livelli: MiaPosizione -> Imposta -> chiamante reale
    vPosizione := PKG_APP.MiaPosizione(3);

    -- Composizione DebugInfo: posizione + eventuale info aggiuntiva
    vDebug := vPosizione;
    IF pDebugInfo IS NOT NULL THEN
      vDebug := vDebug || ' | ' || pDebugInfo;
    END IF;

    -- Costruzione dell'esito
    vEsito := OBJ_Esito(
      vStatusCode,
      NVL(pMessaggio, 'ERRORE GENERICO'),
      CASE WHEN pErrore IS NOT NULL
           THEN '[{"errore": "' || REPLACE(pErrore, '"', '\"') || '"}]'
           ELSE NULL
      END,
      vDebug
    );

    -- Determinazione del livello per il log
    vLivello := CASE
                  WHEN vStatusCode BETWEEN 200 AND 299 THEN 'INFO'
                  WHEN vStatusCode BETWEEN 400 AND 499 THEN 'WARN'
                  ELSE 'ERROR'
                END;

    -- Incremento contatore e generazione chiave progressiva
    vContatore := PKG_APP.IncrementaContatorLog;
    vChiave    := 'LOG_' || LPAD(TO_CHAR(vContatore), 7, '0');

    -- Valore: JSON con i campi principali dell'esito
    vValore := '{"contatore":' || vContatore ||
               ',"livello":"'  || vLivello || '"' ||
               ',"status":'    || vStatusCode ||
               ',"messaggio":"' || REPLACE(NVL(pMessaggio, 'ERRORE GENERICO'), '"', '\"') || '"' ||
               ',"posizione":"' || REPLACE(vPosizione, '"', '\"') || '"' ||
               CASE WHEN pErrore IS NOT NULL
                    THEN ',"errore":"' || REPLACE(pErrore, '"', '\"') || '"'
                    ELSE ''
               END || '}';

    -- Tronca il valore se supera il limite del contesto
    IF LENGTH(vValore) > 4000 THEN
      vValore := SUBSTR(vValore, 1, 3997) || '...';
    END IF;

    PKG_APP.AggiungiContesto('CTX_APP_LOG', vChiave, vValore);

    RETURN vEsito;
  END Imposta;


  -- Verifica se l'esito e positivo (status 2xx)
  MEMBER FUNCTION IsSuccess RETURN BOOLEAN IS
  BEGIN
    RETURN SELF.StatusCode BETWEEN 200 AND 299;
  END IsSuccess;


  -- Verifica se l'esito e un errore (status >= 400)
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
