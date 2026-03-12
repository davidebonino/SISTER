----------------------------------------------------------------------------
-- OBJ_Azione — Operazione atomica del sistema (catalogo delle azioni autorizzabili)
--
-- SCOPO
--   Rappresenta una singola operazione eseguibile nel sistema. Il catalogo delle
--   azioni e la base del sistema RBAC: ogni operazione CRUD di ogni oggetto deve
--   avere una corrispondente azione in TBL_AZIONI per poter essere autorizzata
--   tramite TBL_PRIVILEGI.
--
-- IDENTIFICAZIONE
--   Un'azione e identificata dalla tripla (Tipo, Oggetto, Ambito):
--     Tipo    — tipo di operazione (es. 'INSERIMENTO', 'MODIFICA', 'ELIMINAZIONE', 'VISUALIZZAZIONE')
--     Oggetto — entita su cui agisce (es. 'UTENTE', 'PROFILO', 'AZIONE')
--     Ambito  — contesto opzionale per specializzazioni (NULL = generico)
--
-- OVERLOADING Carica
--   Carica(pIdAzione)               — carica per ID, richiede sessione attiva
--   Carica(pTipo, pOggetto, pAmbito) — carica per tripla, senza verifica sessione
--                                      (usato da PKG_APP.VerificaAccesso)
--
-- METODO Cerca
--   Cerca(pTipo, pOggetto, pAmbito) → restituisce IdAzione o NULL
--   Usato da PKG_APP.VerificaAccesso come primo step del controllo RBAC.
--
-- NOTA: Azione non implementa soft delete (Attivo non presente).
--       Sviluppo futuro: allineare a pattern Utente/Profilo/Privilegio.
--
-- DIPENDENZE
--   UNDER OBJ_Profilatore; referenziato da OBJ_Privilegio (IdAzione)
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Azione UNDER OBJ_Profilatore (
  IdAzione    NUMBER,
  Tipo        VARCHAR2(16),
  Nome        VARCHAR2(64),
  Descrizione VARCHAR2(256),
  Oggetto     VARCHAR2(64),
  Ambito      VARCHAR2(64),
  DataIns     DATE,
  UtenteIns   NUMBER,
  DataAgg     DATE,
  UtenteAgg   NUMBER,
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,
  STATIC FUNCTION Carica(pIdAzione NUMBER) RETURN OBJ_Azione,
  STATIC FUNCTION Carica(pTipo IN VARCHAR2, pOggetto IN VARCHAR2, pAmbito IN VARCHAR2) RETURN OBJ_Azione,
  STATIC FUNCTION Cerca(pTipo IN VARCHAR2, pOggetto IN VARCHAR2, pAmbito IN VARCHAR2) RETURN NUMBER,
  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN,
  MEMBER PROCEDURE Crea,
  MEMBER PROCEDURE Modifica,
  MEMBER PROCEDURE Elimina,
  CONSTRUCTOR FUNCTION OBJ_Azione RETURN SELF AS RESULT
);
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Azione AS

  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Azione RETURN SELF AS RESULT
  IS
  BEGIN
    SELF.IdAzione    := NULL;
    SELF.Tipo        := NULL;
    SELF.Nome        := NULL;
    SELF.Descrizione := NULL;
    SELF.Oggetto     := NULL;
    SELF.Ambito      := NULL;
    SELF.DataIns     := NULL;
    SELF.UtenteIns   := NULL;
    SELF.DataAgg     := NULL;
    SELF.UtenteAgg   := NULL;
    RETURN;
  END;
  --------------------------------------------------------------------------


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'AZIONE';
  END Info;
  --------------------------------------------------------------------------


  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE UPPER(pSinonimo)
      WHEN 'ID_AZIONE'   THEN 'ID_AZIONE|N'
      WHEN 'TIPO'        THEN 'TIPO|V'
      WHEN 'NOME'        THEN 'NOME|V'
      WHEN 'DESCRIZIONE' THEN 'DESCRIZIONE|V'
      WHEN 'OGGETTO'     THEN 'OGGETTO|V'
      WHEN 'AMBITO'      THEN 'AMBITO|V'
      ELSE NULL
    END;
  END RisolviSinonimo;
  --------------------------------------------------------------------------


  -- Esegue i controlli logici prima di operazioni di Crea/Modifica
  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN IS
  BEGIN
    RETURN TRUE;
  END ControlliLogici;
  --------------------------------------------------------------------------


  -- Crea un oggetto Azione nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Crea IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'AZIONE', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.IdAzione  := AZIONI_ID_AZIONE.NEXTVAL;
      SELF.DataIns   := SYSDATE;
      SELF.UtenteIns := OBJ_Utente.MioIdUtente();
      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();

      INSERT INTO TBL_AZIONI (
        ID_AZIONE,
        TIPO,
        NOME,
        DESCRIZIONE,
        OGGETTO,
        AMBITO,
        DATAINS,
        UTENTEINS,
        DATAAGG,
        UTENTEAGG
      ) VALUES (
        SELF.IdAzione,
        SELF.Tipo,
        SELF.Nome,
        SELF.Descrizione,
        SELF.Oggetto,
        SELF.Ambito,
        SELF.DataIns,
        SELF.UtenteIns,
        SELF.DataAgg,
        SELF.UtenteAgg
      );
      SELF.Esito := OBJ_Esito.Imposta(200, 'Azione creata con successo', NULL, NULL);

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Azione non inserita per errore interno', 'Azione non inserita per errore interno' || SQLERRM, SQLERRM);

    END Crea;
  --------------------------------------------------------------------------


  -- Modifica un oggetto Azione nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Modifica IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('MODIFICA', 'AZIONE', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();

      UPDATE TBL_AZIONI SET
        TIPO = SELF.Tipo,
        NOME = SELF.Nome,
        DESCRIZIONE = SELF.Descrizione,
        OGGETTO = SELF.Oggetto,
        AMBITO = SELF.Ambito,
        DATAAGG = SELF.DataAgg,
        UTENTEAGG = SELF.UtenteAgg
      WHERE ID_AZIONE = SELF.IdAzione;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Azione modificata con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Azione non trovata per modifica', 'Azione non trovata per modifica', 'OBJ_Azione.Modifica: Nessun record aggiornato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Azione non modificata per errore interno', 'Azione non modificata per errore interno' || SQLERRM, SQLERRM);

    END Modifica;
  --------------------------------------------------------------------------


  -- Elimina un oggetto Azione nel database
  MEMBER PROCEDURE Elimina IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('ELIMINAZIONE', 'AZIONE', NULL, TRUE);
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      DELETE FROM TBL_AZIONI
      WHERE ID_AZIONE = SELF.IdAzione;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Azione eliminata con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Azione non trovata per eliminazione', 'Azione non trovata per eliminazione', 'OBJ_Azione.Elimina: Nessun record eliminato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Azione non eliminata per errore interno', 'Azione non eliminata per errore interno' || SQLERRM, SQLERRM);

    END Elimina;
  --------------------------------------------------------------------------


  -- Carica l'oggetto Azione per ID
  STATIC FUNCTION Carica(pIdAzione NUMBER) RETURN OBJ_Azione IS
    vAzione OBJ_Azione;
  BEGIN
    vAzione := OBJ_Azione();

    IF OBJ_Utente.MioIdRuolo() IS NOT NULL THEN

      SELECT ID_AZIONE
           , TIPO
           , NOME
           , DESCRIZIONE
           , OGGETTO
           , AMBITO
           , DATAINS
           , UTENTEINS
           , DATAAGG
           , UTENTEAGG
        INTO vAzione.IdAzione,
             vAzione.Tipo,
             vAzione.Nome,
             vAzione.Descrizione,
             vAzione.Oggetto,
             vAzione.Ambito,
             vAzione.DataIns,
             vAzione.UtenteIns,
             vAzione.DataAgg,
             vAzione.UtenteAgg
        FROM TBL_AZIONI AZ
       WHERE AZ.ID_AZIONE = pIdAzione;

      IF vAzione.IdAzione IS NOT NULL THEN
        vAzione.Esito := OBJ_Esito.Imposta(200, 'Azione caricata con successo', NULL, NULL);
        RETURN vAzione;
      ELSE
        vAzione.Esito := OBJ_Esito.Imposta(204, 'Azione non trovata', 'Azione non trovata per i parametri forniti', NULL);
        RETURN vAzione;
      END IF;
    ELSE
      -- Chiamante non autorizzato
      vAzione.Esito := OBJ_Esito.Imposta(401, 'Chiamante non autorizzato', 'Chiamante non autorizzato', NULL);
      RETURN vAzione;
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Azione non trovata
      vAzione.Esito := OBJ_Esito.Imposta(204, 'Azione non trovata, parametri errati', 'Azione non trovata, parametri errati' || SQLERRM, SQLERRM);
      RETURN vAzione  ;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vAzione.Esito := OBJ_Esito.Imposta(500, 'Azione non trovata per errore interno', 'Azione non trovata per errore interno' || SQLERRM, SQLERRM);
      RETURN vAzione;
  END Carica;
  --------------------------------------------------------------------------


  -- Carica l'oggetto Azione per parametri
  STATIC FUNCTION Carica(pTipo IN VARCHAR2, pOggetto IN VARCHAR2, pAmbito IN VARCHAR2) RETURN OBJ_Azione IS
    vAzione OBJ_Azione;
  BEGIN
    vAzione := OBJ_Azione();

    SELECT ID_AZIONE
         , TIPO
         , NOME
         , DESCRIZIONE
         , OGGETTO
         , AMBITO
         , DATAINS
         , UTENTEINS
         , DATAAGG
         , UTENTEAGG
      INTO vAzione.IdAzione,
           vAzione.Tipo,
           vAzione.Nome,
           vAzione.Descrizione,
           vAzione.Oggetto,
           vAzione.Ambito,
           vAzione.DataIns,
           vAzione.UtenteIns,
           vAzione.DataAgg,
           vAzione.UtenteAgg
      FROM TBL_AZIONI AZ
     WHERE (AZ.TIPO    = pTipo    OR pTipo    IS NULL)
       AND (AZ.OGGETTO = pOggetto OR pOggetto IS NULL)
       AND (AZ.AMBITO  = pAmbito  OR pAmbito  IS NULL)
       AND ROWNUM = 1;

     IF vAzione.IdAzione IS NOT NULL THEN
       vAzione.Esito := OBJ_Esito.Imposta(200, 'Azione caricata con successo', NULL, NULL);
       RETURN vAzione;
     ELSE
       vAzione.Esito := OBJ_Esito.Imposta(204, 'Azione non trovata', 'Azione non trovata per i parametri forniti', NULL);
       RETURN vAzione;
     END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Azione non trovata
      vAzione.Esito := OBJ_Esito.Imposta(204, 'Azione non trovata, parametri errati', 'Azione non trovata, parametri errati' || SQLERRM, SQLERRM);
      RETURN vAzione  ;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vAzione.Esito := OBJ_Esito.Imposta(500, 'Azione non trovata per errore interno', 'Azione non trovata per errore interno' || SQLERRM, SQLERRM);
      RETURN vAzione;
  END Carica;
  --------------------------------------------------------------------------


  -- Cerca l'Id dell'oggetto Azione
  -- !!! DA VALUTARE IL NOME DELLA FUNZIONE
  STATIC FUNCTION Cerca(pTipo IN VARCHAR2, pOggetto IN VARCHAR2, pAmbito IN VARCHAR2) RETURN NUMBER IS
    vAzione OBJ_Azione;
  BEGIN
    vAzione := Carica(pTipo, pOggetto, pAmbito);

    IF vAzione.Esito.StatusCode = 200 THEN
       -- Azione trovata restituzione di IdAzione
       RETURN vAzione.IdAzione;
     ELSE
       -- Azione non trovata
       RETURN NULL;
     END IF;
  END Cerca;
  --------------------------------------------------------------------------

END;
