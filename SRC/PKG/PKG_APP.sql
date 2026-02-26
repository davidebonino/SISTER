--CREATE CONTEXT CTX_APP_IDS USING PKG_APP;
--CREATE CONTEXT CTX_APP_PAR USING PKG_APP;
--CREATE CONTEXT CTX_APP_ABL USING PKG_APP;
--CREATE CONTEXT CTX_APP_FLT USING PKG_APP;
--CREATE CONTEXT CTX_APP_LOG USING PKG_APP;


CREATE OR REPLACE PACKAGE SISTER_TST.PKG_APP AS

  -- Costanti per i livelli di debug
  DEBUG_OFF   CONSTANT NUMBER := 0;
  DEBUG_ERROR CONSTANT NUMBER := 1;
  DEBUG_WARN  CONSTANT NUMBER := 2;
  DEBUG_INFO  CONSTANT NUMBER := 3;
  DEBUG_DEBUG CONSTANT NUMBER := 4;
  DEBUG_TRACE CONSTANT NUMBER := 5;

  -- Restituisce la posizione nel codice al momento della chiamata.
  -- pProfondita: 2 = chiamante diretto (default), 3 = chiamante del chiamante, ecc.
  FUNCTION MiaPosizione(pProfondita IN PLS_INTEGER DEFAULT 2) RETURN VARCHAR2;

  -- Inizializzazione della sessione applicativa
  FUNCTION Inizializza(pUsername IN VARCHAR2, pKeyword IN VARCHAR2, pIdProfilo IN NUMBER) RETURN BOOLEAN;

  -- Gestione Application Context
  PROCEDURE CreaContesto(pContesto IN VARCHAR2);
  FUNCTION  EsisteContesto(pContesto IN VARCHAR2) RETURN BOOLEAN;
  PROCEDURE AggiungiContesto(pContesto IN VARCHAR2, pChiave IN VARCHAR2, pValore IN VARCHAR2);
  PROCEDURE RimuoviContesto(pContesto IN VARCHAR2, pChiave IN VARCHAR2);
  PROCEDURE PulisciContesto(pContesto IN VARCHAR2);
  FUNCTION  VisualizzaContesto(pContesto IN VARCHAR2) RETURN VARCHAR2;

  -- Lettura e scrittura parametri di sistema (CTX_APP_PAR)
  FUNCTION  GetParametro(pChiave IN VARCHAR2) RETURN VARCHAR2;
  PROCEDURE SetParametro(pChiave IN VARCHAR2, pValore IN VARCHAR2);

  -- Gestione contatore log
  FUNCTION  GetContatorLog RETURN NUMBER;
  FUNCTION  IncrementaContatorLog RETURN NUMBER;

  -- Verifica autenticazione, privilegio e controlli logici.
    -- Restituisce un OBJ_Esito già pronto:
    --   200  → accesso consentito, il metodo CRUD può procedere
    --   400  → controlli logici falliti
    --   401  → autenticazione mancante o privilegi insufficienti
    --   500  → errore interno
    -- pControlliLogici: risultato di SELF.ControlliLogici(), passato dall'esterno
    --                   perché la logica è specifica di ogni oggetto.
    --                   Passare TRUE se non applicabile (es. Elimina).
    FUNCTION VerificaAccesso(
      pTipoAzione      IN VARCHAR2,
      pOggetto         IN VARCHAR2,
      pAmbito          IN VARCHAR2,
      pControlliLogici IN BOOLEAN DEFAULT TRUE
    ) RETURN OBJ_Esito;

END PKG_APP;

----------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY SISTER_TST.PKG_APP AS

  -- Restituisce la posizione nel codice al momento della chiamata.
  FUNCTION MiaPosizione(pProfondita IN PLS_INTEGER DEFAULT 2) RETURN VARCHAR2 IS
    vRiga      NUMBER;
    vSottoprog VARCHAR2(256);
  BEGIN
    vRiga      := UTL_CALL_STACK.UNIT_LINE(pProfondita);
    vSottoprog := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(
                    UTL_CALL_STACK.SUBPROGRAM(pProfondita)
                  );
    RETURN vSottoprog || ' [riga ' || vRiga || ']';
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'Posizione non disponibile';
  END MiaPosizione;


  -- Lettura di un parametro da CTX_APP_PAR
  FUNCTION GetParametro(pChiave IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN SYS_CONTEXT('CTX_APP_PAR', pChiave);
  END GetParametro;


  -- Scrittura di un parametro in CTX_APP_PAR
  PROCEDURE SetParametro(pChiave IN VARCHAR2, pValore IN VARCHAR2) IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT(
      namespace => 'CTX_APP_PAR',
      attribute => pChiave,
      value     => pValore
    );
  END SetParametro;


  -- Restituisce il valore corrente del contatore log
  FUNCTION GetContatorLog RETURN NUMBER IS
    vContatore VARCHAR2(10);
  BEGIN
    vContatore := SYS_CONTEXT('CTX_APP_PAR', 'LOG_CONTATORE');
    RETURN NVL(TO_NUMBER(vContatore), 0);
  END GetContatorLog;


  -- Incrementa il contatore log e restituisce il nuovo valore
  FUNCTION IncrementaContatorLog RETURN NUMBER IS
    vNuovoContatore NUMBER;
  BEGIN
    vNuovoContatore := GetContatorLog + 1;
    SetParametro('LOG_CONTATORE', TO_CHAR(vNuovoContatore));
    RETURN vNuovoContatore;
  END IncrementaContatorLog;


  -- Inizializzazione della sessione applicativa
  FUNCTION Inizializza(pUsername IN VARCHAR2, pKeyword IN VARCHAR2, pIdProfilo IN NUMBER) RETURN BOOLEAN AS
    vSessione        OBJ_Sessione;
    vProfilo         OBJ_Profilo;
    vUtente          OBJ_Utente;
    vNumAbilitazioni NUMBER;
  BEGIN

    -- Inizializzazione parametri di sistema con valori di default
    SetParametro('DEBUG_LEVEL',      TO_CHAR(DEBUG_OFF));
    SetParametro('DEBUG_ENABLED',    'N');
    SetParametro('DEBUG_FLUSH_SIZE', '10');
    SetParametro('DEBUG_MSG_COUNT',  '0');
    SetParametro('DEBUG_BUFFER',     NULL);
    SetParametro('LOG_CONTATORE',    '0');

    -- Creazione sessione e caricamento identita
    vSessione := OBJ_Sessione.Crea(pUsername, pKeyword, pIdProfilo);
    IF vSessione.IdSessione IS NOT NULL THEN
      AggiungiContesto('CTX_APP_IDS', 'ID_SESSIONE', vSessione.IdSessione);

      vProfilo := OBJ_Profilo.Carica(vSessione.IdProfilo);
      IF vProfilo.IdProfilo IS NOT NULL THEN
        AggiungiContesto('CTX_APP_IDS', 'ID_PROFILO', vProfilo.IdProfilo);
        AggiungiContesto('CTX_APP_IDS', 'ID_RUOLO',   vProfilo.IdRuolo);
        vNumAbilitazioni := OBJ_Profilo.CaricaContestoAbilitazioni(vProfilo.IdProfilo);

        vUtente := OBJ_Utente.Carica(vProfilo.IdUtente);
        IF vUtente.IdUtente IS NOT NULL THEN
          AggiungiContesto('CTX_APP_IDS', 'ID_UTENTE', vUtente.IdUtente);
          RETURN TRUE;
        ELSE
          DBMS_OUTPUT.PUT_LINE('Errore nel caricamento dell''UTENTE: ' || vUtente.Esito.Messaggio);
          RETURN FALSE;
        END IF;
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nel caricamento del PROFILO');
        RETURN FALSE;
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento della SESSIONE');
      RETURN FALSE;
    END IF;
  END Inizializza;


  -- Verifica se un contesto applicativo esiste gia
  FUNCTION EsisteContesto(pContesto IN VARCHAR2) RETURN BOOLEAN IS
    vConteggio NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO vConteggio
      FROM DBA_CONTEXT
     WHERE NAMESPACE = UPPER(TRIM(pContesto));
    RETURN vConteggio > 0;
  END EsisteContesto;


  -- Creazione di un contesto applicativo (solo se non esiste gia)
  PROCEDURE CreaContesto(pContesto IN VARCHAR2) IS
  BEGIN
    IF NOT EsisteContesto(pContesto) THEN
      EXECUTE IMMEDIATE 'CREATE CONTEXT ' || DBMS_ASSERT.SIMPLE_SQL_NAME(pContesto) || ' USING PKG_APP';
    END IF;
  END CreaContesto;


  -- Aggiunta di una chiave/valore in un contesto applicativo
  PROCEDURE AggiungiContesto(pContesto IN VARCHAR2, pChiave IN VARCHAR2, pValore IN VARCHAR2) IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT(
      namespace => pContesto,
      attribute => pChiave,
      value     => pValore
    );
  END AggiungiContesto;


  -- Rimozione di una singola chiave da un contesto applicativo
  PROCEDURE RimuoviContesto(pContesto IN VARCHAR2, pChiave IN VARCHAR2) IS
  BEGIN
    DBMS_SESSION.CLEAR_CONTEXT(
      namespace => pContesto,
      attribute => pChiave
    );
  END RimuoviContesto;


  -- Pulizia completa di un contesto applicativo
  PROCEDURE PulisciContesto(pContesto IN VARCHAR2) IS
  BEGIN
    DBMS_SESSION.CLEAR_CONTEXT(pContesto);
  END PulisciContesto;


  -- Visualizzazione di tutte le coppie chiave/valore di un contesto applicativo
  FUNCTION VisualizzaContesto(pContesto IN VARCHAR2) RETURN VARCHAR2 IS
    vOutput VARCHAR2(4000);
  BEGIN
    FOR vRec IN (
      SELECT attribute, value
        FROM SESSION_CONTEXT
       WHERE namespace = UPPER(TRIM(pContesto))
       ORDER BY attribute
    ) LOOP
      vOutput := vOutput || vRec.attribute || ' = ' || vRec.value || CHR(10);
    END LOOP;
    RETURN vOutput;
  END VisualizzaContesto;


  -- VERIFICA ACCESSO
  FUNCTION VerificaAccesso(
    pTipoAzione      IN VARCHAR2,
    pOggetto         IN VARCHAR2,
    pAmbito          IN VARCHAR2,
    pControlliLogici IN BOOLEAN DEFAULT TRUE
  ) RETURN OBJ_Esito IS
    vIdAzione    NUMBER;
    vIdPrivilegio NUMBER;
  BEGIN

    -- Passo 1: verifica autenticazione
    IF OBJ_Profilatore.MioIdRuolo() IS NULL THEN
      RETURN OBJ_Esito.Imposta(
        401,
        pOggetto || ' non ' || LOWER(pTipoAzione) || ', autenticazione mancante',
        'MioIdRuolo IS NULL',
        'PKG_APP.VerificaAccesso: ' || pTipoAzione || ' su ' || pOggetto
      );
    END IF;

    -- Passo 2: ricerca azione e privilegio
    vIdAzione := OBJ_Azione.Cerca(pTipoAzione, pOggetto, pAmbito);

    IF vIdAzione IS NULL THEN
      RETURN OBJ_Esito.Imposta(
        401,
        pOggetto || ' non ' || LOWER(pTipoAzione) || ', azione non configurata',
        'Azione non trovata: ' || pTipoAzione || '/' || pOggetto || '/' || NVL(pAmbito, 'NULL'),
        'PKG_APP.VerificaAccesso: OBJ_Azione.Cerca ha restituito NULL'
      );
    END IF;

    vIdPrivilegio := OBJ_Privilegio.Cerca(vIdAzione, OBJ_Profilatore.MioIdRuolo());

    IF vIdPrivilegio IS NULL THEN
      RETURN OBJ_Esito.Imposta(
        401,
        pOggetto || ' non ' || LOWER(pTipoAzione) || ', privilegi insufficienti',
        'IdPrivilegio NULL per IdAzione=' || vIdAzione || ', IdRuolo=' || OBJ_Profilatore.MioIdRuolo(),
        'PKG_APP.VerificaAccesso: OBJ_Privilegio.Cerca ha restituito NULL'
      );
    END IF;

    -- Passo 3: controlli logici dell'oggetto chiamante
    IF NOT NVL(pControlliLogici, TRUE) THEN
      RETURN OBJ_Esito.Imposta(
        400,
        pOggetto || ' non ' || LOWER(pTipoAzione) || ', errori nei controlli logici',
        'ControlliLogici ha restituito FALSE',
        'PKG_APP.VerificaAccesso: ControlliLogici falliti per ' || pOggetto
      );
    END IF;

    -- Tutto ok
    RETURN OBJ_Esito.Imposta(200, 'Accesso consentito', NULL, NULL);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN OBJ_Esito.Imposta(
        500,
        'Verifica accesso non riuscita per errore interno',
        'Verifica accesso non riuscita' || SQLERRM,
        SQLERRM
      );
  END VerificaAccesso;

END PKG_APP;
